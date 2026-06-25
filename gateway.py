"""
OmniSense Edge Gateway v3.2 (Synchronized Architecture)
"""

import cv2
import numpy as np
import urllib.request
import urllib.error
import paho.mqtt.client as mqtt
import threading
import queue
import time
import os
import csv
import json
from collections import defaultdict
from insightface.app import FaceAnalysis
import faiss

# ─── CONFIGURATION ────────────────────────────────────────────────────────────
ESP32_IP        = "10.95.187.9"          
ESP32_BASE_URL  = f"http://{ESP32_IP}"
ESP32_STREAM    = f"{ESP32_BASE_URL}/"     
ESP32_SNAP      = f"{ESP32_BASE_URL}/snap" 

MQTT_BROKER     = "www.mqtt-dashboard.com"
MQTT_PORT       = 1883
DATASET_FOLDER  = "dataset"
ATTENDANCE_LOG  = "attendance_log.csv"

FAISS_THRESHOLD  = 1.45   
COOLDOWN_SECS    = 30     
UNKNOWN_COOLDOWN = 10     
LERP_ALPHA       = 0.35   
AI_MIN_INTERVAL  = 0.05   
AI_MAX_INTERVAL  = 0.50   

MJPEG_BOUNDARY   = b"frame"              
MAX_BUF_BYTES    = 1_048_576             

# ─── SHUTDOWN ─────────────────────────────────────────────────────────────────
_stop = threading.Event()

# ─── SHARED FRAME BUFFER ──────────────────────────────────────────────────────
_frame_lock   = threading.Lock()
_latest_frame = None

def _write_frame(f):
    global _latest_frame
    with _frame_lock:
        _latest_frame = f

def _read_frame():
    with _frame_lock:
        return None if _latest_frame is None else _latest_frame.copy()

# ─── SHARED ENTITY LIST ───────────────────────────────────────────────────────
_entity_lock = threading.Lock()
_entities    = []

def _write_entities(lst):
    with _entity_lock:
        global _entities
        _entities = lst

def _read_entities():
    with _entity_lock:
        return list(_entities)

# ─── MQTT QUEUE ───────────────────────────────────────────────────────────────
_mqtt_queue: queue.Queue = queue.Queue(maxsize=64)

# ─── STREAM STATE ─────────────────────────────────────────────────────────────
_stream_active = False
_system_status = "AWAITING STREAM"

# ─── AI INIT ──────────────────────────────────────────────────────────────────
print("[BOOT] Initializing OmniSense v3.2 …")
face_app = FaceAnalysis(name='buffalo_l')
# FIX: Reduced det_size from (640,640) to (320,320) — halves AI processing time per frame
face_app.prepare(ctx_id=-1, det_size=(320, 320))

faiss_index = faiss.IndexFlatL2(512)
student_dir: list[str] = []
_cooldown = defaultdict(float)


# ─── HELPERS ──────────────────────────────────────────────────────────────────

def _lerp_box(prev, curr, alpha=LERP_ALPHA):
    if prev is None:
        return curr
    return [int(p + alpha * (c - p)) for p, c in zip(prev, curr)]


def log_attendance(sid: str):
    exists = os.path.isfile(ATTENDANCE_LOG)
    with open(ATTENDANCE_LOG, 'a', newline='') as f:
        w = csv.writer(f)
        if not exists:
            w.writerow(["Timestamp", "Student ID", "Status"])
        w.writerow([time.strftime("%Y-%m-%d %H:%M:%S"), sid, "Present"])


def load_dataset():
    os.makedirs(DATASET_FOLDER, exist_ok=True)
    count = 0
    for fn in sorted(os.listdir(DATASET_FOLDER)):
        if not fn.lower().endswith(('.png', '.jpg', '.jpeg')):
            continue
        name = os.path.splitext(fn)[0]
        path = os.path.join(DATASET_FOLDER, fn)
        try:
            import PIL.Image, PIL.ImageOps
            pil  = PIL.ImageOps.exif_transpose(PIL.Image.open(path))
            img  = cv2.cvtColor(np.array(pil), cv2.COLOR_RGB2BGR)
        except Exception:
            img  = cv2.imdecode(np.fromfile(path, dtype=np.uint8), cv2.IMREAD_COLOR)
        if img is None:
            continue
        faces = face_app.get(img)
        if not faces:
            continue
        best = max(faces, key=lambda f: (f.bbox[2]-f.bbox[0])*(f.bbox[3]-f.bbox[1]))
        emb  = best.embedding / np.linalg.norm(best.embedding)
        faiss_index.add(np.array([emb], dtype=np.float32))
        student_dir.append(name)
        count += 1
        print(f"[ENROLL] ✅  {name}")
    return count


def _snapshot_check() -> bool:
    try:
        resp = urllib.request.urlopen(ESP32_SNAP, timeout=4)
        data = resp.read(65536)
        ok   = data[:2] == b'\xff\xd8'
        print(f"[HEALTH] Snapshot check → {'OK ✅' if ok else 'bad data ❌'}")
        return ok
    except Exception as e:
        print(f"[HEALTH] Snapshot check failed: {e}")
        return False


# ─── THREAD 1: STREAM FETCHER ─────────────────────────────────────────────────

def _fetch_opencv(url: str) -> bool:
    global _stream_active, _system_status
    cap = cv2.VideoCapture(url, cv2.CAP_FFMPEG)
    # FIX: Minimal internal buffer to prevent frame queue buildup (the main lag source)
    cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
    cap.set(cv2.CAP_PROP_FOURCC, cv2.VideoWriter_fourcc(*'MJPG'))
    cap.set(cv2.CAP_PROP_FPS, 20)
    cap.set(cv2.CAP_PROP_OPEN_TIMEOUT_MSEC, 3000)

    if not cap.isOpened():
        cap.release()
        return False

    _stream_active = True
    _system_status = "LIVE — OPENCV"

    while not _stop.is_set():
        # FIX: Drain the internal decode buffer — grab() without decode, then
        # retrieve() only the freshest frame. Eliminates accumulated-frame lag.
        cap.grab()
        cap.grab()
        ok, frame = cap.retrieve()
        if not ok:
            break
        _write_frame(frame)
        # No sleep here — grab() acts as the natural pacemaker

    cap.release()
    return True

def _fetch_urllib(url: str) -> bool:
    global _stream_active, _system_status
    try:
        resp = urllib.request.urlopen(url, timeout=5)
    except Exception as e:
        return False

    _stream_active = True
    _system_status = "LIVE — URLLIB"
    buf = b""
    try:
        while not _stop.is_set():
            chunk = resp.read(8192)
            if not chunk:
                break
            buf += chunk

            if len(buf) > MAX_BUF_BYTES:
                buf = b""
                continue

            boundary_marker = b"--" + MJPEG_BOUNDARY
            parts = buf.split(boundary_marker)
            if len(parts) > 1:
                # FIX: Skip all but the LAST part to avoid processing stale frames
                last_valid = None
                for part in parts[:-1]:
                    soi = part.find(b'\xff\xd8')
                    eoi = part.rfind(b'\xff\xd9')
                    if soi != -1 and eoi != -1 and eoi > soi:
                        last_valid = part[soi:eoi+2]
                if last_valid is not None:
                    frame = cv2.imdecode(np.frombuffer(last_valid, dtype=np.uint8), cv2.IMREAD_COLOR)
                    if frame is not None:
                        _write_frame(frame)
                buf = parts[-1]
                continue

            soi = buf.find(b'\xff\xd8')
            eoi = buf.find(b'\xff\xd9')
            if soi != -1 and eoi != -1 and eoi > soi:
                jpg   = buf[soi:eoi+2]
                buf   = buf[eoi+2:]
                frame = cv2.imdecode(np.frombuffer(jpg, dtype=np.uint8), cv2.IMREAD_COLOR)
                if frame is not None:
                    _write_frame(frame)
    except Exception as e:
        pass
    return True 
# Replace this specific function inside your gateway.py file

def fetch_stream():
    global _stream_active, _system_status
    delay = 1.0
    time.sleep(1.0)
    _snapshot_check()
    print(f"[STREAM] Connecting to {ESP32_STREAM}")
    while not _stop.is_set():
        _stream_active = False
        _system_status = "RECONNECTING …"
        
        # [FIX APPLIED]: Priority swapped. _fetch_urllib is significantly faster 
        # for MJPEG streams because it avoids OpenCV's internal FFMPEG buffer queue.
        connected = _fetch_urllib(ESP32_STREAM) or _fetch_opencv(ESP32_STREAM)
        
        _stream_active = False
        if not connected:
            _system_status = f"OFFLINE — retry {int(delay)}s"
            delay = min(delay * 2, 32.0)
        else:
            delay = 1.0 
        _stop.wait(delay)

# ─── THREAD 2: ADAPTIVE AI WORKER ─────────────────────────────────────────────

def ai_worker():
    prev_boxes: dict[int, list] = {}
    interval = 0.1

    while not _stop.is_set():
        t0    = time.perf_counter()
        frame = _read_frame()
        if frame is None:
            time.sleep(0.05)
            continue

        faces    = face_app.get(frame)
        ents     = []
        now      = time.time()

        for idx, face in enumerate(faces):
            raw_box = face.bbox.astype(int).tolist()
            box     = _lerp_box(prev_boxes.get(idx), raw_box)
            prev_boxes[idx] = box

            emb   = face.embedding / np.linalg.norm(face.embedding)
            color = (0, 0, 255)
            label = "Unknown"

            if faiss_index.ntotal > 0:
                D, I  = faiss_index.search(np.array([emb], dtype=np.float32), 1)
                dist  = float(D[0][0])
                name  = student_dir[int(I[0][0])]

                if dist < FAISS_THRESHOLD:
                    color, label = (0, 200, 0), name
                    if now - _cooldown[label] > COOLDOWN_SECS:
                        _cooldown[label] = now
                        log_attendance(label)
                        _mqtt_queue.put_nowait(("omnisense/attendance", {
                            "type": "auth", "userId": label,
                            "epoch": int(now), "action": "grant_access"
                        }))
                        _mqtt_queue.put_nowait(("omnisense/buzzer", {"state": "known"}))
                        print(f"[AUTH] ✅  {label} — logged & webhooks queued.")
                else:
                    if now - _cooldown["__unknown__"] > UNKNOWN_COOLDOWN:
                        _cooldown["__unknown__"] = now
                        _mqtt_queue.put_nowait(("omnisense/security", {
                            "type": "alert", "level": "critical",
                            "reason": "unrecognized_entity", "epoch": int(now)
                        }))
                        _mqtt_queue.put_nowait(("omnisense/buzzer", {"state": "unknown"}))
                        print("[SECURITY] ⚠️  Unknown entity detected.")

            ents.append({"box": box, "label": label, "color": color})

        prev_boxes = {i: e["box"] for i, e in enumerate(ents)}
        _write_entities(ents)

        elapsed  = time.perf_counter() - t0
        interval = float(np.clip(elapsed * 1.5, AI_MIN_INTERVAL, AI_MAX_INTERVAL))
        time.sleep(interval)


# ─── THREAD 3: MQTT WORKER ────────────────────────────────────────────────────

def mqtt_worker():
    client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
    delay  = 1.0

    while not _stop.is_set():
        try:
            client.connect(MQTT_BROKER, MQTT_PORT, keepalive=60)
            client.loop_start()
            delay = 1.0
            print("[MQTT] Connected.")
            client.publish("omnisense/gateway/status", "{\"device\":\"python_gateway\",\"status\":\"online\"}")
            
            while not _stop.is_set():
                try:
                    topic, payload = _mqtt_queue.get(timeout=1.0)
                    client.publish(topic, json.dumps(payload))
                except queue.Empty:
                    pass
            client.loop_stop()
        except Exception as e:
            print(f"[MQTT] Failed ({e}). Retry in {delay:.0f}s")
            _stop.wait(delay)
            delay = min(delay * 2, 32.0)


# ─── MAIN: SMOOTH UI ──────────────────────────────────────────────────────────

def _make_placeholder(w=640, h=480):
    canvas = np.zeros((h, w, 3), dtype=np.uint8)
    cv2.putText(canvas, "Connecting to ESP32-CAM …",
                (w//2 - 200, h//2), cv2.FONT_HERSHEY_SIMPLEX,
                0.8, (80, 80, 80), 2, cv2.LINE_AA)
    return canvas

def _draw_hud(canvas, status: str, active: bool):
    h, w = canvas.shape[:2]
    cv2.rectangle(canvas, (0, 0), (w, 52), (15, 15, 15), -1)
    cv2.putText(canvas, "OMNISENSE EDGE GATEWAY v3.2",
                (16, 32), cv2.FONT_HERSHEY_SIMPLEX, 0.72,
                (220, 220, 220), 2, cv2.LINE_AA)
    sc = (30, 200, 30) if active else (60, 60, 200)
    cv2.putText(canvas, status,
                (w - 370, 32), cv2.FONT_HERSHEY_SIMPLEX, 0.56,
                sc, 2, cv2.LINE_AA)
    ts = time.strftime("%Y-%m-%d  %H:%M:%S")
    cv2.rectangle(canvas, (0, h - 32), (w, h), (15, 15, 15), -1)
    cv2.putText(canvas, ts,
                (16, h - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.50,
                (130, 130, 130), 1, cv2.LINE_AA)

def _draw_entity(canvas, ent: dict):
    x1, y1, x2, y2 = ent["box"]
    color = ent["color"]
    label = ent["label"]
    overlay = canvas.copy()
    lw = max(160, len(label) * 11)
    cv2.rectangle(overlay, (x1, max(0, y1 - 32)), (x1 + lw, y1), color, -1)
    cv2.addWeighted(overlay, 0.55, canvas, 0.45, 0, canvas)
    cv2.rectangle(canvas, (x1, y1), (x2, y2), color, 2, cv2.LINE_AA)
    cv2.putText(canvas, label,
                (x1 + 6, max(14, y1 - 9)),
                cv2.FONT_HERSHEY_SIMPLEX, 0.62,
                (255, 255, 255), 2, cv2.LINE_AA)

def run_ui():
    TARGET_FPS = 30
    frame_ms   = int(1000 / TARGET_FPS)
    placeholder = _make_placeholder()

    while not _stop.is_set():
        t0    = time.perf_counter()
        frame = _read_frame()

        canvas = placeholder if frame is None else frame
        for ent in _read_entities():
            _draw_entity(canvas, ent)
        _draw_hud(canvas, _system_status, _stream_active)
        cv2.imshow("OmniSense Central Terminal", canvas)

        elapsed_ms = int((time.perf_counter() - t0) * 1000)
        wait_ms    = max(1, frame_ms - elapsed_ms)
        if cv2.waitKey(wait_ms) & 0xFF == ord('q'):
            print("[SHUTDOWN] User quit.")
            _stop.set()
            break

    cv2.destroyAllWindows()


if __name__ == "__main__":
    print("=" * 60)
    print("  OmniSense Edge Gateway v3.2")
    print(f"  Stream URL  : {ESP32_STREAM}")
    print("=" * 60)

    n = load_dataset()
    print(f"[DB] {n} identities enrolled.\n")

    threading.Thread(target=fetch_stream, name="StreamFetcher", daemon=True).start()
    threading.Thread(target=ai_worker,    name="AIWorker",      daemon=True).start()
    threading.Thread(target=mqtt_worker,  name="MQTTWorker",    daemon=True).start()

    run_ui()
    print("[EXIT] Shutdown complete.")
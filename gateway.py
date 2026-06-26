
"""
OmniSense Edge Gateway - Enterprise Multi-Room Dashboard
"""

import cv2
import numpy as np
import urllib.request
import threading
import time
import os
import csv
import requests
import json
import queue
import sys
import tkinter as tk
from tkinter import ttk, filedialog, messagebox
from collections import defaultdict
from insightface.app import FaceAnalysis
import faiss

# ─── DYNAMIC CONFIGURATION MANAGER ────────────────────────────────────────────
CONFIG_FILE = "omnisense_config.json"

DEFAULT_CONFIG = {
    "CUSTOMER_CASE_NUMBER": "SYS-2026-OMNI",
    "BASE_LOG_DIR": "C:/OmniSense_Logs",
    "DATASET_FOLDER": "dataset",
    "FAISS_THRESHOLD": 1.45,
    "CLASSROOM_FLEET": {
        "Room_101": {
            "CAMERA_IP": "10.95.187.9",
            "MAIN_NODE_URL": "http://10.95.187.172"
        }
    }
}

def load_config():
    if not os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, 'w') as f:
            json.dump(DEFAULT_CONFIG, f, indent=4)
        return DEFAULT_CONFIG.copy()
    
    with open(CONFIG_FILE, 'r') as f:
        try:
            loaded_config = json.load(f)
            needs_save = False
            for key, value in DEFAULT_CONFIG.items():
                if key not in loaded_config:
                    loaded_config[key] = value
                    needs_save = True
            if needs_save:
                with open(CONFIG_FILE, 'w') as f_write:
                    json.dump(loaded_config, f_write, indent=4)
            return loaded_config
        except json.JSONDecodeError:
            with open(CONFIG_FILE, 'w') as f_write:
                json.dump(DEFAULT_CONFIG, f_write, indent=4)
            return DEFAULT_CONFIG.copy()

def save_config(cfg):
    with open(CONFIG_FILE, 'w') as f:
        json.dump(cfg, f, indent=4)

config = load_config()

# ─── GLOBALS & STATE ENGINE ───────────────────────────────────────────────────
_stop = threading.Event()
_stop.set()

_room_queues = {}          # Maps room_name -> queue.Queue(maxsize=1)
_camera_statuses = {}      # Maps room_name -> string status
_room_occupancies = {}     # Maps room_name -> active student count

_presence_lock = threading.Lock()
_active_presence = defaultdict(dict)  # Maps room_name -> {student_name: timestamp}
_unknown_cooldowns = defaultdict(float) # Maps room_name -> timestamp
_liveness_tracker = defaultdict(lambda: defaultdict(list))

face_app = None
faiss_index = None
student_dir = []

# ─── SECURE AUDIT LOGGING ─────────────────────────────────────────────────────
def get_log_directories(room_name: str):
    date_str = time.strftime("%Y-%m-%d")
    base_dir = os.path.join(config["BASE_LOG_DIR"], date_str)
    img_dir = os.path.join(base_dir, f"Images_{room_name}")
    
    os.makedirs(base_dir, exist_ok=True)
    os.makedirs(os.path.join(img_dir, "Known"), exist_ok=True)
    os.makedirs(os.path.join(img_dir, "Unknown"), exist_ok=True)
    os.makedirs(os.path.join(img_dir, "Spoof_Attempts"), exist_ok=True)
    return base_dir, img_dir

def log_attendance(sid: str, room_name: str):
    base_dir, _ = get_log_directories(room_name)
    csv_path = os.path.join(base_dir, f"{room_name}.csv")
    exists = os.path.isfile(csv_path)
    try:
        with open(csv_path, 'a', newline='', encoding='utf-8') as f:
            w = csv.writer(f)
            if not exists: w.writerow(["Timestamp", "Student ID", "Status"])
            w.writerow([time.strftime("%Y-%m-%d %H:%M:%S"), sid, "Present"])
    except IOError: pass

def save_audit_image(frame, room_name: str, category: str, identifier: str):
    _, img_dir = get_log_directories(room_name)
    timestamp = time.strftime("%H-%M-%S")
    filename = f"{timestamp}_{identifier}.jpg"
    filepath = os.path.join(img_dir, category, filename)
    cv2.imwrite(filepath, frame)

def trigger_hardware_async(status: str, room_name: str):
    def _send():
        try:
            fleet = config["CLASSROOM_FLEET"]
            if room_name in fleet:
                url = f"{fleet[room_name]['MAIN_NODE_URL']}/ring?face={status}&room={room_name}"
                requests.get(url, timeout=2)
        except requests.exceptions.RequestException: pass
    threading.Thread(target=_send, daemon=True).start()

def load_dataset_engine():
    global faiss_index, face_app, student_dir
    student_dir = []
    
    if face_app is None:
        face_app = FaceAnalysis(name='buffalo_l')
        face_app.prepare(ctx_id=-1, det_size=(320, 320))
        
    faiss_index = faiss.IndexFlatL2(512)
    os.makedirs(config["DATASET_FOLDER"], exist_ok=True)
    
    count = 0
    for fn in sorted(os.listdir(config["DATASET_FOLDER"])):
        if not fn.lower().endswith(('.png', '.jpg', '.jpeg')): continue
        name = os.path.splitext(fn)[0]
        path = os.path.join(config["DATASET_FOLDER"], fn)
        img = cv2.imdecode(np.fromfile(path, dtype=np.uint8), cv2.IMREAD_COLOR)
        if img is None: continue
        faces = face_app.get(img)
        if not faces: continue
        best = max(faces, key=lambda f: (f.bbox[2]-f.bbox[0])*(f.bbox[3]-f.bbox[1]))
        emb = best.embedding / np.linalg.norm(best.embedding)
        faiss_index.add(np.array([emb], dtype=np.float32))
        student_dir.append(name)
        count += 1
    return count

# ─── MULTI-STREAM NETWORK WORKER ──────────────────────────────────────────────
def fetch_room_stream(room_name: str, ip: str):
    stream_url = f"http://{ip}/"
    
    while not _stop.is_set():
        try:
            resp = urllib.request.urlopen(stream_url, timeout=5)
            buf = b""
            _camera_statuses[room_name] = "Online"
            
            while not _stop.is_set():
                chunk = resp.read(8192)
                if not chunk: break
                buf += chunk
                if len(buf) > 1_048_576: buf = b""; continue
                parts = buf.split(b"--frame")
                if len(parts) > 1:
                    last_valid = None
                    for part in parts[:-1]:
                        soi, eoi = part.find(b'\xff\xd8'), part.rfind(b'\xff\xd9')
                        if soi != -1 and eoi != -1 and eoi > soi:
                            last_valid = part[soi:eoi+2]
                    if last_valid is not None:
                        frame = cv2.imdecode(np.frombuffer(last_valid, dtype=np.uint8), cv2.IMREAD_COLOR)
                        if frame is not None and room_name in _room_queues:
                            q = _room_queues[room_name]
                            if q.full():
                                try: q.get_nowait()
                                except queue.Empty: pass
                            q.put(frame)
                    buf = parts[-1]
        except Exception:
            _camera_statuses[room_name] = "Connection Lost"
            time.sleep(2.0)

# ─── FLEET AI PROCESSING PIPELINE ─────────────────────────────────────────────
def ai_processing_core():
    while not _stop.is_set():
        frames_to_process = []
        for room, q in _room_queues.items():
            if not q.empty():
                frames_to_process.append((room, q.get()))

        if not frames_to_process:
            time.sleep(0.01)
            continue
            
        now = time.time()
        
        for room_name, frame in frames_to_process:
            if face_app is None: continue
            faces = face_app.get(frame)
            
            frame_has_known = False
            unknown_present = False
            
            with _presence_lock:
                room_presence = _active_presence[room_name]
                room_liveness = _liveness_tracker[room_name]

                # Clear old data (15 seconds threshold)
                for name in list(room_presence.keys()):
                    if now - room_presence[name] > 15.0:
                        del room_presence[name]
                        if name in room_liveness: del room_liveness[name]

                if faces:
                    for face in faces:
                        x1, y1, x2, y2 = face.bbox.astype(int)
                        face_area = (x2 - x1) * (y2 - y1)
                        
                        if faiss_index is not None and faiss_index.ntotal > 0:
                            emb = face.embedding / np.linalg.norm(face.embedding)
                            D, I = faiss_index.search(np.array([emb], dtype=np.float32), 1)
                            
                            if float(D[0][0]) < config["FAISS_THRESHOLD"]:
                                name = student_dir[int(I[0][0])]
                                frame_has_known = True
                                
                                history = room_liveness[name]
                                history.append(face_area)
                                if len(history) > 4: history.pop(0)
                                
                                is_live = False
                                is_spoof = False
                                if len(history) >= 3:
                                    variance = max(history) - min(history)
                                    if variance > (0.010 * np.mean(history)): is_live = True
                                    else: is_spoof = True
                                
                                if name not in room_presence:
                                    if is_live:
                                        log_attendance(name, room_name)
                                        save_audit_image(frame, room_name, "Known", name)
                                        trigger_hardware_async("known", room_name)
                                        room_presence[name] = now
                                    elif is_spoof:
                                        save_audit_image(frame, room_name, "Spoof_Attempts", name)
                                else:
                                    room_presence[name] = now
                                continue
                        unknown_present = True

                _room_occupancies[room_name] = len(room_presence)

            if unknown_present and not frame_has_known:
                if now - _unknown_cooldowns[room_name] > 10.0:
                    _unknown_cooldowns[room_name] = now
                    save_audit_image(frame, room_name, "Unknown", "Stranger")
                    trigger_hardware_async("unknown", room_name)

        time.sleep(0.01)

# ─── ENTERPRISE MANAGEMENT GUI ────────────────────────────────────────────────
class OmniSenseGUI(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("OmniSense Edge Security")
        self.geometry("750x550")
        self.configure(padx=20, pady=20)
        
        style = ttk.Style(self)
        style.theme_use('clam')
        
        # Header Row
        header_frame = ttk.Frame(self)
        header_frame.pack(fill="x", pady=(0, 15))
        ttk.Label(header_frame, text="OmniSense Central Gateway", font=("Segoe UI", 16, "bold")).pack(side="left")
        ttk.Label(header_frame, text=f"Deployment ID: {config['CUSTOMER_CASE_NUMBER']}", font=("Segoe UI", 10)).pack(side="right", anchor="s")

        # Configurations View
        config_frame = ttk.LabelFrame(self, text="System Directory Settings", padding=15)
        config_frame.pack(fill="x", pady=5)

        ttk.Label(config_frame, text="Log Output Path:").grid(row=0, column=0, sticky="w", pady=5)
        self.logdir_var = tk.StringVar(value=config["BASE_LOG_DIR"])
        ttk.Entry(config_frame, textvariable=self.logdir_var, width=55, state="readonly").grid(row=0, column=1, padx=10)
        ttk.Button(config_frame, text="Select Folder", command=self.browse_logdir).grid(row=0, column=2)

        # Dynamic Fleet Input Panel
        fleet_input_frame = ttk.LabelFrame(self, text="Dynamic Fleet Setup", padding=15)
        fleet_input_frame.pack(fill="x", pady=10)
        
        ttk.Label(fleet_input_frame, text="Location:").grid(row=0, column=0, sticky="w")
        self.room_ent = ttk.Entry(fleet_input_frame, width=12)
        self.room_ent.grid(row=0, column=1, padx=5)
        
        ttk.Label(fleet_input_frame, text="Camera IP:").grid(row=0, column=2, sticky="w")
        self.ip_ent = ttk.Entry(fleet_input_frame, width=14)
        self.ip_ent.grid(row=0, column=3, padx=5)
        
        ttk.Label(fleet_input_frame, text="Node URL:").grid(row=0, column=4, sticky="w")
        self.node_ent = ttk.Entry(fleet_input_frame, width=22)
        self.node_ent.grid(row=0, column=5, padx=5)
        
        ttk.Button(fleet_input_frame, text="Add Room", command=self.add_fleet_item).grid(row=0, column=6, padx=5)
        ttk.Button(fleet_input_frame, text="Remove", command=self.remove_fleet_item).grid(row=0, column=7, padx=5)

        # Monitoring View Table
        dash_frame = ttk.LabelFrame(self, text="Active Fleet Status Dashboard", padding=15)
        dash_frame.pack(fill="both", expand=True, pady=5)
        
        columns = ("room", "ip", "status", "occupancy")
        self.tree = ttk.Treeview(dash_frame, columns=columns, show="headings", height=5)
        self.tree.heading("room", text="Monitored Location")
        self.tree.heading("ip", text="Camera Interface")
        self.tree.heading("status", text="Hardware Connection")
        self.tree.heading("occupancy", text="Active Occupancy")
        
        self.tree.column("room", anchor="w", width=150)
        self.tree.column("ip", anchor="center", width=130)
        self.tree.column("status", anchor="center", width=150)
        self.tree.column("occupancy", anchor="center", width=120)
        self.tree.pack(fill="both", expand=True, pady=5)
        
        # System Management Controls
        control_frame = ttk.Frame(self)
        control_frame.pack(fill="x", pady=(15, 0))
        
        self.status_lbl = ttk.Label(control_frame, text="System Control Status: OFFLINE", font=("Segoe UI", 10, "bold"), foreground="gray")
        self.status_lbl.pack(side="left")
        
        self.stop_btn = ttk.Button(control_frame, text="Stop Infrastructure", command=self.stop_system, state="disabled")
        self.stop_btn.pack(side="right", padx=5)
        
        self.start_btn = ttk.Button(control_frame, text="Initialize Infrastructure", command=self.start_system)
        self.start_btn.pack(side="right", padx=5)

        # Initialize UI tables and statuses
        self.refresh_ui_table_structure()
        self.update_dashboard_telemetry_loop()

    def browse_logdir(self):
        folder = filedialog.askdirectory(title="Select Log Base Directory")
        if folder:
            self.logdir_var.set(folder)
            config["BASE_LOG_DIR"] = folder
            save_config(config)

    def refresh_ui_table_structure(self):
        if not _stop.is_set(): return
        for item in self.tree.get_children():
            self.tree.delete(item)
        for room, data in config["CLASSROOM_FLEET"].items():
            self.tree.insert("", tk.END, iid=room, values=(room, data["CAMERA_IP"], "Offline", "0"))

    def add_fleet_item(self):
        if not _stop.is_set(): return
        room = self.room_ent.get().strip()
        ip = self.ip_ent.get().strip()
        node = self.node_ent.get().strip()
        
        if not room or not ip or not node:
            messagebox.showwarning("Incomplete Fields", "Please populate all fields to add a room.")
            return
            
        config["CLASSROOM_FLEET"][room] = {"CAMERA_IP": ip, "MAIN_NODE_URL": node}
        save_config(config)
        self.refresh_ui_table_structure()
        self.room_ent.delete(0, tk.END); self.ip_ent.delete(0, tk.END); self.node_ent.delete(0, tk.END)

    def remove_fleet_item(self):
        if not _stop.is_set(): return
        selected = self.tree.selection()
        if not selected: return
        for room_id in selected:
            if room_id in config["CLASSROOM_FLEET"]:
                del config["CLASSROOM_FLEET"][room_id]
        save_config(config)
        self.refresh_ui_table_structure()

    def update_dashboard_telemetry_loop(self):
        """ Pulls memory parameters directly into UI table cells smoothly """
        if not _stop.is_set():
            for room in config["CLASSROOM_FLEET"].keys():
                stat = _camera_statuses.get(room, "Initializing")
                occ = _room_occupancies.get(room, 0)
                if self.tree.exists(room):
                    self.tree.set(room, column="status", value=stat)
                    self.tree.set(room, column="occupancy", value=str(occ))
        else:
            for room in config["CLASSROOM_FLEET"].keys():
                if self.tree.exists(room):
                    self.tree.set(room, column="status", value="Offline")
                    self.tree.set(room, column="occupancy", value="0")
                    
        self.after(1000, self.update_dashboard_telemetry_loop)

    def start_system(self):
        if not config["CLASSROOM_FLEET"]:
            messagebox.showerror("Empty Fleet", "Add at least one monitoring location before initialization.")
            return
            
        self.start_btn.config(state="disabled")
        self.stop_btn.config(state="normal")
        self.status_lbl.config(text="System Control Status: INITIALIZING PLATFORM...", foreground="orange")
        _stop.clear()
        
        threading.Thread(target=self._boot_sequence, daemon=True).start()

    def _boot_sequence(self):
        global _room_queues, _camera_statuses, _room_occupancies
        
        _room_queues.clear()
        _camera_statuses.clear()
        _room_occupancies.clear()
        
        # Build strict dynamic memory pipes matching the exact fleet size
        for room in config["CLASSROOM_FLEET"].keys():
            _room_queues[room] = queue.Queue(maxsize=1)
            _camera_statuses[room] = "Connecting"
            _room_occupancies[room] = 0

        load_dataset_engine()
        
        # Spin up threads mapping to each unique workspace context
        for room, data in config["CLASSROOM_FLEET"].items():
            threading.Thread(target=fetch_room_stream, args=(room, data["CAMERA_IP"]), daemon=True).start()
            
        threading.Thread(target=ai_processing_core, daemon=True).start()
        self.status_lbl.config(text="System Control Status: ACTIVE RUNTIME", foreground="green")

    def stop_system(self):
        _stop.set()
        self.start_btn.config(state="normal")
        self.stop_btn.config(state="disabled")
        self.status_lbl.config(text="System Control Status: OFFLINE", foreground="gray")
        self.refresh_ui_table_structure()

if __name__ == "__main__":
    # Ensure background system redirects standard console handles invisibly
    sys.stdout = open(os.devnull, 'w')
    sys.stderr = open(os.devnull, 'w')
    
    app = OmniSenseGUI()
    app.mainloop()
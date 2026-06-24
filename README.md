# EdgeAttend (OmniSense Edge Gateway v3.2)

EdgeAttend is a real-time, face-recognition-based smart attendance and security monitoring system using a synchronized Edge-IoT architecture. It processes video streams from ESP32-CAM edge nodes, runs high-performance face recognition using InsightFace and FAISS, logs attendance locally, and synchronizes system events via MQTT to trigger peripheral actions (like buzzers or alerts).

---

## Architecture Overview

```
                      +-------------------+
                      |   ESP32-CAM Node  |
                      |  (HTTP Stream)    |
                      +---------+---------+
                                | (MJPEG Stream)
                                v
                      +-------------------+
                      |    Edge Gateway   | <----+ (Loads Student Images)
                      |    (Python AI)    |      |
                      +---------+---------+      +---+ [dataset/]
                                |                    |
          +---------------------+--------------------+
          | (MQTT Event Logs)                        | (MQTT Commands)
          v                                          v
+-------------------+                      +-------------------+
+   MQTT Broker     |                      |     ESP32 Node    |
+ (HiveMQ Dashboard)+--------------------->| (Buzzer & Alerts) |
+-------------------+                      +-------------------+
```

1. **ESP32-CAM Node (`server_ip/`)**: Captures images and exposes a live MJPEG stream and health snapshot endpoints over HTTP.
2. **Edge Gateway (`gateway.py`)**:
   - Streams video from the ESP32-CAM.
   - Extracts face embeddings using **InsightFace** (`buffalo_l` model).
   - Performs low-latency similarity searches using **FAISS** against the pre-loaded `dataset/` (images of authorized users).
   - Records attendance into `attendance_log.csv`.
   - Publishes JSON events to MQTT topics for auth grants or security warnings.
3. **ESP32 Buzzer/Actuator Node (`espMain/`)**: Subscribes to MQTT and rings a buzzer to indicate whether the scanned face is recognized (1s) or unrecognized (5s).

---

## Repository Structure

```
EdgeAttend/
├── dataset/                  # Folder containing student reference images (e.g., student_id.png)
│   └── .gitkeep              # Placeholder to preserve the directory structure
├── espMain/
│   └── espMain.ino           # Arduino code for the buzzer/actuator ESP32 unit
├── server_ip/
│   └── server_ip.ino         # Arduino code for the ESP32-CAM streaming unit
├── gateway.py                # Python Edge Gateway script (runs InsightFace + FAISS + UI)
├── .gitignore                # Git ignore patterns (ignores local images, csv log, pycache)
└── README.md                 # This file
```

---

## Setup & Running Instructions

### 1. Hardware Configuration

- **ESP32-CAM**: Pinouts configured for **AI-THINKER** boards.
- **ESP32 Actuator**: Pin `GPIO 4` is configured for the buzzer.
- Edit the network credentials in the following files with your Wi-Fi SSID and Password before uploading:
  - `espMain/espMain.ino` (lines 6-7)
  - `server_ip/server_ip.ino` (lines 7-8)

### 2. Gateway Environment Setup

You need a Python environment (Python 3.8+ recommended) with the following dependencies installed:

```bash
pip install opencv-python numpy paho-mqtt insightface faiss-cpu pillow
```

> [!NOTE]
> - **InsightFace** requires ONNX Runtime. If you have an NVIDIA GPU, you can install `onnxruntime-gpu` and run InsightFace on CUDA by changing `ctx_id=0` in `FaceAnalysis(name='buffalo_l')` preparation.
> - **FAISS**: Install `faiss-cpu` or `faiss-gpu` depending on your environment.

### 3. Populating Reference Images (The Database)

Add JPG/PNG face images of students/personnel to the `dataset/` folder.
- Name the files matching their ID/Name (e.g., `1RV24CS031.png` or `John_Doe.jpeg`).
- The gateway will automatically detect faces in these images at startup, generate their embedding templates, and register them to the FAISS index.

### 4. Running the System

1. **Deploy Edge Nodes**:
   - Power on the **ESP32-CAM** and notice the IP address printed on the Serial Monitor (e.g., `10.52.144.133`).
   - Power on the **ESP32 Actuator** node and verify it connects to the same Wi-Fi and MQTT broker.

2. **Configure Gateway IP**:
   - Open `gateway.py` and update `ESP32_IP` (line 21) to match your ESP32-CAM's IP address:
     ```python
     ESP32_IP = "10.52.144.133"
     ```

3. **Launch the Gateway**:
   - Run the Python script:
     ```bash
     python gateway.py
     ```
   - A window titled **"OmniSense Central Terminal"** will open, showing the live feed, recognized bounding boxes, HUD details, and system statuses.
   - Present faces in front of the ESP32-CAM.
     - **Authorized**: Logs attendance to `attendance_log.csv` and publishes a MQTT trigger to ring the buzzer for 1 second.
     - **Unauthorized**: Publishes a security alert to MQTT to ring the buzzer for 5 seconds.

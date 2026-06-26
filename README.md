# OmniSense Edge Security System

OmniSense is an enterprise-grade IoT edge computing platform designed for smart classroom monitoring, automated attendance, and real-time security. It leverages distributed ESP32 microcontrollers, Time-of-Flight (ToF) laser sensors, and a centralized Python gateway powered by AI facial recognition.

## System Architecture

The OmniSense infrastructure is built on three core components:

### 1. OmniSense Edge Gateway (`gateway.py`)
A centralized management console built with Python and Tkinter. It acts as the brain of the operation, processing incoming telemetry and video streams.
- **AI Face Recognition**: Uses `insightface` and `faiss` to perform real-time facial recognition on incoming camera streams to automate student attendance and detect unauthorized strangers (spoofing/liveness detection included).
- **Live CCTV Dashboard**: Features a dynamic UI with a live CCTV feed viewer, allowing security personnel to monitor any classroom over the local network.
- **Hardware Integration**: Constantly polls connected hardware nodes to update the dashboard with live room occupancy, connection status, and telemetry.
- **Auto-Discovery**: Automatically discovers connected fleet nodes on the local subnet.

### 2. Main Hardware Node (`espMain.ino`)
An ESP32-based microcontroller placed at the entrance of a room.
- **ToF Occupancy Tracking**: Uses a SparkFun VL53L1X Time-of-Flight sensor to accurately track people entering and exiting the room via bi-directional laser zones, maintaining a highly accurate occupancy count.
- **Automated Relay Control**: Automatically toggles a relay (e.g., room lights or HVAC) based on the occupancy count (turns off when empty).
- **Access Acknowledgment**: Features a buzzer that is triggered remotely by the gateway to provide a short audible beep when an authorized (known) person is recognized. Unauthorized (unknown) persons are logged silently without triggering an alarm.
- **RESTful API**: Hosts local endpoints like `/status` (returns live occupancy JSON) and `/ring` (triggers the buzzer).

### 3. Camera Node (`server_ip.ino`)
An ESP32-CAM module positioned for facial capture.
- **MJPEG Streaming**: Serves a continuous, high-framerate MJPEG video stream over HTTP.
- **MQTT Integration**: Connects to an MQTT broker for lightweight telemetry and remote status broadcasting.
- **Optimized for Edge**: Operates efficiently to provide low-latency frames directly to the AI Gateway.

## Installation & Setup

### Prerequisites
- Python 3.10+
- `pip install -r requirements.txt` (Required libraries: `opencv-python`, `numpy`, `pillow`, `insightface`, `faiss-cpu`, `requests`)
- Arduino IDE for flashing ESP32 modules.

### Flashing the Hardware
1. **ESP32 Main Node**: Open `espMain/espMain.ino`. Update the `ssid` and `password` variables with your local Wi-Fi credentials. Flash to a standard ESP32.
2. **ESP32-CAM Node**: Open `server_ip/server_ip.ino`. Update the `ssid` and `password` variables. Flash to an AI Thinker ESP32-CAM module.

### Running the Gateway
1. Ensure all ESP32 modules are powered on and connected to the same Wi-Fi network as the host machine.
2. Run the gateway:
   ```bash
   python gateway.py
   ```
3. Use the **Dynamic Fleet Setup** panel to add your rooms. Enter the Room Name, the IP of the ESP32-CAM, and the URL of the ESP32 Main Node.
4. Click **Initialize Infrastructure** to start the AI processing pipeline and live monitoring.

## Directory Structure
- `/espMain/` - Source code for the ESP32 Main Node (ToF, LCD, Buzzer).
- `/server_ip/` - Source code for the ESP32-CAM Node (MJPEG Streamer).
- `gateway.py` - Main Python application and AI pipeline.
- `omnisense_config.json` - Automatically generated configuration file storing fleet IPs and settings.
- `/dataset/` - Directory for storing known face reference images.
- `/Attendance_Logs/` - Auto-generated CSV logs and audit images for tracking events.

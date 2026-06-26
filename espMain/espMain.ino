#include <WiFi.h>
#include <WebServer.h> 
#include <ESPmDNS.h>
#include <Wire.h>
#include "SparkFun_VL53L1X.h" 
#include <LiquidCrystal_I2C.h> 

const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

#define BUZZER_PIN 12 
#define RELAY_PIN 26 
#define SDA_PIN 21
#define SCL_PIN 22

WiFiClient espClient;
WebServer server(80); 
SFEVL53L1X distanceSensor;
LiquidCrystal_I2C lcd(0x27, 16, 2);


unsigned long buzzerTimer = 0;
unsigned long buzzerDuration = 0;
bool isBuzzerActive = false;

int occupancyCount = 0;
const int DISTANCE_THRESHOLD = 1200; // mm
const int ROI_WIDTH = 8;
const int ROI_HEIGHT = 16;
int center1 = 167; 
int center2 = 231; 
int currentZone = 1;
int pathState = 0; 

void updateLCD(String topMessage = "OmniSense Active") {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(topMessage);
  lcd.setCursor(0, 1);
  lcd.print("Occupancy: ");
  lcd.print(occupancyCount);
}

void setup_wifi() {
  delay(10);
  Serial.println("\nConnecting to WiFi...");
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected.");
  Serial.print("ESP32 IP Address: ");
  Serial.println(WiFi.localIP());

  if (!MDNS.begin("omnisense")) {
    Serial.println("Error setting up MDNS responder!");
  } else {
    Serial.println("mDNS responder started: http://omnisense.local");
  }
}


void handleRing() {
  // Allow cross-origin requests from any dashboard/app
  server.sendHeader("Access-Control-Allow-Origin", "*");

  if (server.hasArg("face")) {
    String faceStatus = server.arg("face");
    
    if (faceStatus == "known") {
      Serial.println("API Trigger: Known Face. Ringing buzzer!");
      updateLCD("Access Granted!"); 
      buzzerDuration = 1000; 
      isBuzzerActive = true;
      buzzerTimer = millis();
      digitalWrite(BUZZER_PIN, HIGH);
      server.send(200, "text/plain", "Success: Known face acknowledged");
    } 
    else if (faceStatus == "unknown") {
      Serial.println("API Trigger: Unknown Face. Silent Alert!");
      updateLCD("Alert: Unknown!"); 
      
      // Removed the 5-second buzzer logic here.
      // The screen will update, but it will remain completely silent.
      
      server.send(200, "text/plain", "Success: Unknown face logged silently");
    }
  } else {
    server.send(400, "text/plain", "Error: Missing 'face' parameter");
  }
}

void handleStatus() {
  server.sendHeader("Access-Control-Allow-Origin", "*"); // CORS Header
  String json = "{\"occupancy\": " + String(occupancyCount) + ", \"relay\": \"" + (digitalRead(RELAY_PIN) ? "ON" : "OFF") + "\"}";
  server.send(200, "application/json", json);
}

// --- HARDWARE LOGIC ---

void processToF() {
  // NON-BLOCKING: Only process if the sensor actually has new data ready
  if (distanceSensor.checkForDataReady()) {
    int distance = distanceSensor.getDistance(); 
    distanceSensor.clearInterrupt();
    distanceSensor.stopRanging(); // Pause ranging to safely update hardware zones

    bool personDetected = (distance > 0 && distance < DISTANCE_THRESHOLD);
    bool countChanged = false;

    if (currentZone == 1) {
      if (personDetected && pathState == 0) {
        pathState = 1; 
      } else if (!personDetected && pathState == 2) {
        if (occupancyCount > 0) occupancyCount--;
        pathState = 0;
        countChanged = true;
      }
      distanceSensor.setROI(ROI_WIDTH, ROI_HEIGHT, center2);
      currentZone = 2;
    } else {
      if (personDetected && pathState == 0) {
        pathState = 2; 
      } else if (!personDetected && pathState == 1) {
        occupancyCount++;
        pathState = 0;
        countChanged = true;
      }
      distanceSensor.setROI(ROI_WIDTH, ROI_HEIGHT, center1);
      currentZone = 1;
    }

    // If the count changed, update LCD and Relay
    if (countChanged) {
      Serial.print("New Occupancy: ");
      Serial.println(occupancyCount);
      updateLCD(); 
      
      if (occupancyCount > 0) {
        digitalWrite(RELAY_PIN, HIGH);
      } else {
        digitalWrite(RELAY_PIN, LOW);
      }
    }
    
    // Restart ranging with the new zone settings
    distanceSensor.startRanging();
  }
}

void setup() {
  Serial.begin(115200);
  Wire.begin(SDA_PIN, SCL_PIN);
  
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW);
  digitalWrite(RELAY_PIN, LOW);

  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print("Booting...");

  setup_wifi();

  server.on("/ring", HTTP_GET, handleRing);
  server.on("/status", HTTP_GET, handleStatus);
  server.begin();
  Serial.println("HTTP Server Started");

  if (distanceSensor.begin() != 0) {
    Serial.println("VL53L1X Sensor failed!");
    lcd.clear();
    lcd.print("ToF Sensor Error");
  } else {
    distanceSensor.setDistanceModeShort(); 
    distanceSensor.setTimingBudgetInMs(20); 
    distanceSensor.setIntermeasurementPeriod(25);
    distanceSensor.setROI(ROI_WIDTH, ROI_HEIGHT, center1);
    distanceSensor.startRanging(); // Kick off the first range
  }

  updateLCD();
}

void loop() {
  // 1. Process incoming HTTP requests instantly
  server.handleClient();
  
  // 2. Process laser sensor data
  processToF();

  // 3. Handle Buzzer timeouts automatically
  if (isBuzzerActive && (millis() - buzzerTimer >= buzzerDuration)) {
    digitalWrite(BUZZER_PIN, LOW);
    isBuzzerActive = false;
    Serial.println("Buzzer turned OFF.");
    updateLCD(); 
  }
}
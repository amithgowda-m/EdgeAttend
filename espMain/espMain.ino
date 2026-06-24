#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

// --- CONFIGURATION ---
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";
const char* mqtt_server = "www.mqtt-dashboard.com"; // Forces IPv4 fallback to bypass Android hotspot restrictions
const int mqtt_port = 1883;

// --- HARDWARE PINS ---
#define BUZZER_PIN 4 // Change this to the pin connected to your buzzer

WiFiClient espClient;
PubSubClient client(espClient);

// --- NON-BLOCKING TIMER VARIABLES ---
unsigned long buzzerTimer = 0;
unsigned long buzzerDuration = 0;
bool isBuzzerActive = false;

void setup_wifi() {
  delay(10);
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nWiFi connected.");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
}

// Callback triggers when a message is published to subscribed topics
void callback(char* topic, byte* payload, unsigned int length) {
  Serial.print("Message arrived on topic: ");
  Serial.println(topic);

  // Parse the JSON payload
  StaticJsonDocument<200> doc;
  DeserializationError error = deserializeJson(doc, payload, length);

  if (error) {
    Serial.print("JSON Parse failed: ");
    Serial.println(error.c_str());
    return;
  }

  const char* state = doc["state"];
  
  if (strcmp(state, "known") == 0) {
    Serial.println("Action: Known face detected. Buzzer ON for 1s.");
    buzzerDuration = 1000;
    isBuzzerActive = true;
    buzzerTimer = millis();
    digitalWrite(BUZZER_PIN, HIGH);
  } 
  else if (strcmp(state, "unknown") == 0) {
    Serial.println("Action: Unknown face detected. Buzzer ON for 5s.");
    buzzerDuration = 5000;
    isBuzzerActive = true;
    buzzerTimer = millis();
    digitalWrite(BUZZER_PIN, HIGH);
  }
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    // Create a random client ID
    String clientId = "ESP32Main-";
    clientId += String(random(0xffff), HEX);
    
    if (client.connect(clientId.c_str())) {
      Serial.println("connected");
      // Subscribe to the newly created buzzer topic
      client.subscribe("omnisense/buzzer");
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);
  
  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW);

  setup_wifi();
  
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop(); // Keeps MQTT connection alive and polls for messages

  // Non-blocking buzzer timer
  if (isBuzzerActive && (millis() - buzzerTimer >= buzzerDuration)) {
    digitalWrite(BUZZER_PIN, LOW);
    isBuzzerActive = false;
    Serial.println("Buzzer turned OFF.");
  }
}
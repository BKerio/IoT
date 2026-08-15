#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>

// =====================================
// WIFI CONFIGURATION
// =====================================

const char* ssid = "Hivemind";
const char* password = "P#821743056zj";

// =====================================
// BACKEND CONFIGURATION
// =====================================

const char* api_readings = "http://192.168.1.148:8000/api/bins/readings";

// Must match DEVICE_API_KEY in Django's .env.
const char* device_key = "ec897de2c356be27bed7a3c51e906be07e21dd209e038ab8";
const char* device_id = "bin-1";

#define TRIG_PIN 5
#define ECHO_PIN 18

unsigned long lastSendTime = 0;
const unsigned long SEND_INTERVAL_MS = 5000; // post to Django every 5 seconds

// =====================================
// WIFI CONNECTION
// =====================================

void connectWiFi() {
  WiFi.begin(ssid, password);
  Serial.print("Connecting WiFi");

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println();
  Serial.println("WiFi Connected");
  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());
}

void setup() {
  Serial.begin(115200);
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

  connectWiFi();
}

float getDistanceCM() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);

  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  long duration = pulseIn(ECHO_PIN, HIGH, 30000);
  float distance = (duration * 0.0343) / 2;

  return distance;
}

// =====================================
// SEND READING TO DJANGO
// =====================================

void sendReading(float distance) {
  if (WiFi.status() != WL_CONNECTED) return;

  HTTPClient http;
  http.begin(api_readings);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("X-Device-Key", device_key);

  DynamicJsonDocument doc(256);
  doc["device_id"] = device_id;
  doc["distance_cm"] = distance;

  String requestBody;
  serializeJson(doc, requestBody);

  int httpResponseCode = http.POST(requestBody);

  if (httpResponseCode == 200) {
    Serial.println("Reading sent: " + http.getString());
  } else {
    Serial.print("Failed to send reading, HTTP code: ");
    Serial.println(httpResponseCode);
  }

  http.end();
}

void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi disconnected, reconnecting...");
    connectWiFi();
  }

  float distance = getDistanceCM();

  Serial.print("Distance: ");
  Serial.print(distance);
  Serial.println(" cm");

  if (millis() - lastSendTime > SEND_INTERVAL_MS) {
    lastSendTime = millis();
    sendReading(distance);
  }

  delay(500);
}

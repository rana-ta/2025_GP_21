#include <Wire.h>
#include <ESP8266WiFi.h>

#include <MAX30105.h>
#include <spo2_algorithm.h>

#include <Firebase_ESP_Client.h>
#include <Adafruit_MLX90614.h>

// ===================== WiFi =====================
#define WIFI_SSID     ""   //  wifi credentails
#define WIFI_PASSWORD ""   //  wifi credentails

// ===================== Firebase =====================
#define API_KEY "AIzaSyB8qVAcLPsMS2tLEonGFsw7Yz8VFF9mtBo"
#define DATABASE_URL "https://moeenapp-9a886-default-rtdb.firebaseio.com/"

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// ===================== Sensors =====================
MAX30105 particleSensor;
Adafruit_MLX90614 mlx = Adafruit_MLX90614();

bool maxOk = false;
bool mlxOk = false;

// MAX buffers
#define BUFFER_SIZE 80
uint32_t irBuffer[BUFFER_SIZE];
uint32_t redBuffer[BUFFER_SIZE];

int32_t spo2;
int8_t validSPO2;
int32_t heartRate;
int8_t validHeartRate;

float smoothHR = 0;
float smoothSpO2 = 0;
bool fingerOff = false;

float estimatedTemp = 0;

// ===================== MPU6050 Fall sensor =====================
const int MPU_addr = 0x68;  // I2C address of MPU-6050

int16_t AcX, AcY, AcZ, Tmp, GyX, GyY, GyZ;
float ax=0, ay=0, az=0, gx=0, gy=0, gz=0;

bool trigger1=false;  // free-fall trigger
bool trigger2=false;  // impact trigger
bool trigger3=false;  // rotation trigger

unsigned long t1=0, t2=0, t3=0;
byte lowAmpCount = 0;

bool possibleFall = false;
unsigned long possibleFallStart = 0;

// ===================== BUZZER =====================
#define BUZZER_PIN D5
bool alarmActive = false;
unsigned long alarmStart = 0;
const unsigned long ALARM_DURATION_MS = 10000; //10 secons buzzer duration

// ===================== FALL EVENT COOLDOWN =====================
unsigned long lastFallEvent = 0;
const unsigned long FALL_COOLDOWN_MS = 8000;

// ===================== FALL CONFIRM + 3 MIN =====================
const unsigned long BUZZER_DELAY_S = 180; // after 3 minute
unsigned long lastStatusPoll = 0;
const unsigned long STATUS_POLL_MS = 1000;
unsigned long pendingTimestamp = 0;

// ===================== Sensor upload timing =====================
unsigned long previousMillis = 0;
bool firstSend = true;
const unsigned long first_interval = 60000;  // 1 min
const unsigned long normal_interval = 10000; // 10 sec

// ===================== Debug =====================
unsigned long lastHeartbeat = 0;

// ---------- I2C SCAN ----------
void scanI2C() {
  Serial.println("\nI2C scan start...");
  int found = 0;
  for (byte addr = 1; addr < 127; addr++) {
    Wire.beginTransmission(addr);
    if (Wire.endTransmission() == 0) {
      Serial.print("Found 0x");
      if (addr < 16) Serial.print("0");
      Serial.println(addr, HEX);
      found++;
    }
    delay(2);
  }
  if (found == 0) Serial.println("❌ No I2C devices found!");
  else Serial.println("✅ I2C scan done.");
}

// ---------- BUZZER FUNCTIONS ----------
void startBuzzer() {
  alarmActive = true;
  alarmStart = millis();
  digitalWrite(BUZZER_PIN, HIGH); // immediate ON for active buzzer
  Serial.println("🔊 BUZZER START");
}

void updateBuzzer() {
  if (!alarmActive) {
    digitalWrite(BUZZER_PIN, LOW);
    return;
  }

  if (millis() - alarmStart > ALARM_DURATION_MS) {
    alarmActive = false;
    digitalWrite(BUZZER_PIN, LOW);
    Serial.println("🔇 BUZZER STOP");
    return;
  }

  // beep pattern: 200ms ON / 200ms OFF
  if (((millis() - alarmStart) / 200) % 2 == 0) digitalWrite(BUZZER_PIN, HIGH);
  else digitalWrite(BUZZER_PIN, LOW);
}

// ---------- MPU READ  ----------
void mpu_read() {
  Wire.beginTransmission(MPU_addr);
  Wire.write(0x3B);
  Wire.endTransmission(false);
  Wire.requestFrom(MPU_addr, 14, true);

  AcX = Wire.read() << 8 | Wire.read();
  AcY = Wire.read() << 8 | Wire.read();
  AcZ = Wire.read() << 8 | Wire.read();
  Tmp = Wire.read() << 8 | Wire.read();
  GyX = Wire.read() << 8 | Wire.read();
  GyY = Wire.read() << 8 | Wire.read();
  GyZ = Wire.read() << 8 | Wire.read();
}

// ---------- Send fall to Firebase: PENDING + timestamp ----------
void sendFallPendingToFirebase(unsigned long tsSeconds ) {
  if (!Firebase.RTDB.setString(&fbdo, "/fall/status", "PENDING"))
    Serial.println("❌ set /fall/status failed: " + fbdo.errorReason());

  if (!Firebase.RTDB.setInt(&fbdo, "/fall/timestamp", (int)tsSeconds))
    Serial.println("❌ set /fall/timestamp failed: " + fbdo.errorReason());

  Serial.println("✅ Firebase: PENDING sent");
}

// ---------- SINGLE FALL HANDLER (PENDING only, no immediate buzzer) ----------
void triggerFallEvent() {
  if (millis() - lastFallEvent < FALL_COOLDOWN_MS) return;
  lastFallEvent = millis();

  Serial.println("FALL DETECTED -> sent PENDING (waiting CONFIRMED or 1min)");
  unsigned long tsSeconds  = millis() / 1000;
  sendFallPendingToFirebase(tsSeconds );
}

// ---------- Poll Firebase: CONFIRMED now OR 3-min pending ----------
void pollFallStatusAndHandleBuzzer() {
  if (millis() - lastStatusPoll < STATUS_POLL_MS) return;
  lastStatusPoll = millis();

  // Local "only once" guards
  static bool confirmedHandled = false;
  static bool pendingBuzzerHandled = false;

  if (!Firebase.RTDB.getString(&fbdo, "/fall/status")) {
    Serial.println("❌ get /fall/status failed: " + fbdo.errorReason());
    return;
  }

  String status = fbdo.stringData();
  status.trim();

  // User OK -> reset too NONE
  if (status == "OK") {
    Serial.println("🛑 OK received -> stopping buzzer & resetting system");

    // Stop buzzer immediately
    alarmActive = false;
    digitalWrite(BUZZER_PIN, LOW);

    // Reset internal flags
    confirmedHandled = false;
    pendingBuzzerHandled = false;

    // Clear Firebase state
    Firebase.RTDB.setString(&fbdo, "/fall/status", "NONE");
    Firebase.RTDB.setInt(&fbdo, "/fall/timestamp", 0);

    return;
  }

  if (status == "NONE") {
    confirmedHandled = false;
    pendingBuzzerHandled = false;
    return;
  }


  // ✅ CONFIRMED -> buzzer ON only once,  NOT changing status 
  if (status == "CONFIRMED") {
    if (!confirmedHandled) {
      Serial.println("🚨 CONFIRMED -> buzzer ON (device will NOT clear status)");
      startBuzzer();
      confirmedHandled = true;
    }
    return;
  }

  // ✅ PENDING -> after delay, buzzer ON only once
  if (status == "PENDING") {
    if (!Firebase.RTDB.getInt(&fbdo, "/fall/timestamp")) {
      Serial.println("❌ get /fall/timestamp failed: " + fbdo.errorReason());
      return;
    }

    pendingTimestamp = (unsigned long)fbdo.intData();
    unsigned long nowS = millis() / 1000;
    unsigned long elapsed = (nowS >= pendingTimestamp) ? (nowS - pendingTimestamp) : 0;

    static byte c = 0;
    if (++c % 5 == 0) {
      Serial.print("⏳ PENDING elapsed(s)=");
      Serial.println(elapsed);
    }

    if (elapsed >= BUZZER_DELAY_S) {
      if (!pendingBuzzerHandled) {
        Serial.println("⏱️ Delay passed -> buzzer ON (and set CONFIRMED)");
        startBuzzer();
        pendingBuzzerHandled = true;

        Firebase.RTDB.setString(&fbdo, "/fall/status", "CONFIRMED");
      }
    } else {
      // If still pending, allow future trigger
      pendingBuzzerHandled = false;
    }

    return;
  }

  // Any other unknown status -> do nothing
}


// ---------- Sensor reading ----------
void handleSensorReading() {
  // MAX30102
  if (!maxOk) {
    smoothHR = 0;
    smoothSpO2 = 0;
    fingerOff = true;
  } else {
    for (int i = 0; i < BUFFER_SIZE; i++) {
      unsigned long t = millis();
      while (!particleSensor.available()) {
        particleSensor.check();
        if (millis() - t > 200) return; // don't freeze
      }
      redBuffer[i] = particleSensor.getRed();
      irBuffer[i]  = particleSensor.getIR();
      particleSensor.nextSample();
    }

    maxim_heart_rate_and_oxygen_saturation(
      irBuffer, BUFFER_SIZE, redBuffer,
      &spo2, &validSPO2, &heartRate, &validHeartRate
    );

    fingerOff = (particleSensor.getIR() < 25000);

    if (fingerOff) {
      smoothHR = 0;
      smoothSpO2 = 0;
      validHeartRate = 0;
      validSPO2 = 0;
    } else {
      const float HR_OFFSET = -10.0;
      if (validHeartRate && heartRate > 40 && heartRate < 130) {
        float calibratedHR = heartRate + HR_OFFSET;
        smoothHR = 0.8 * smoothHR + 0.2 * calibratedHR;
      }
      if (validSPO2 && spo2 > 80 && spo2 <= 100) {
        smoothSpO2 = 0.7 * smoothSpO2 + 0.3 * spo2;
      }
    }
  }

  // MLX
  if (!mlxOk) {
    estimatedTemp = 0;
  } else {
    float obj = mlx.readObjectTempC();
    estimatedTemp = round((obj + 8.5) * 10) / 10.0;
  }
}

// ---------- Firebase sensorData upload ----------
void sendSensorData() {
  unsigned long now = millis();
  unsigned long interval = firstSend ? first_interval : normal_interval;
  if (now - previousMillis < interval) return;

  previousMillis = now;
  if (firstSend) {
    firstSend = false;
    Serial.println("First 1-minute send completed. Now every 10 seconds...");
  }

  FirebaseJson json;
  json.set("heartRate", (int)smoothHR);
  json.set("spo2", (int)smoothSpO2);
  json.set("ir", maxOk ? (int)irBuffer[BUFFER_SIZE - 1] : 0);
  json.set("red", maxOk ? (int)redBuffer[BUFFER_SIZE - 1] : 0);
  json.set("status", fingerOff ? "not connected" : "connected");
  json.set("temperature", estimatedTemp);

  if (Firebase.RTDB.setJSON(&fbdo, "/sensorData", &json)) {
    Serial.println("✅ sensorData sent");
  } else {
    Serial.println("❌ sensorData failed: " + fbdo.errorReason());
  }
}


//  FALL DETECTION sensor
void fallDetection() {
  mpu_read();

  // Calibrations (keep yours)
  ax = (AcX - 2050) / 16384.0;
  ay = (AcY - 77) / 16384.0;
  az = (AcZ - 1947) / 16384.0;

  gx = (GyX + 270) / 131.07;
  gy = (GyY - 351) / 131.07;
  gz = (GyZ + 136) / 131.07;

  float rawAmp = sqrt(ax*ax + ay*ay + az*az);
  int Amp = (int)(rawAmp * 10);

  int gyroMag = (int)sqrt(gx*gx + gy*gy + gz*gz);

  // Print Amp 
  static unsigned long lastPrint = 0;
  if (millis() - lastPrint > 200) {
    lastPrint = millis();
    Serial.println(Amp);
  }

  // 1) NORMAL 
  if (Amp > 6 && Amp < 10 && gyroMag < 40) {
    trigger1 = trigger2 = trigger3 = false;
    lowAmpCount = 0;
    possibleFall = false;
  }

  // 2) SLOW FALL DETECTION
  if (!possibleFall) {
    if ((Amp > 6 && Amp < 12 && gyroMag > 30) || (Amp >= 12 && gyroMag > 40)) {
      possibleFall = true;
      possibleFallStart = millis();
    }
  }

  if (possibleFall) {
    if (gyroMag < 15 && (millis() - possibleFallStart > 1200)) {
      triggerFallEvent();
      possibleFall = false;
    }

    if (millis() - possibleFallStart > 4000) {
      possibleFall = false;
    }
  }

  // 3) FAST FALL (FREE FALL → IMPACT → ROTATION → STILLNESS)
  if (Amp <= 5) lowAmpCount++;
  else lowAmpCount = 0;

  if (lowAmpCount >= 2 && !trigger1) {
    trigger1 = true;
    t1 = millis();
  }

  if (trigger1 && Amp >= 15 && (millis() - t1 < 500)) {
    trigger2 = true;
    trigger1 = false;
    t2 = millis();
  }

  if (trigger2 && gyroMag >= 120 && (millis() - t2 < 800)) {
    trigger3 = true;
    trigger2 = false;
    t3 = millis();
  }

  if (trigger3) {
    if (gyroMag < 15 && (millis() - t3 > 600)) {
      triggerFallEvent();
      trigger3 = false;
    }

    if (millis() - t3 > 2000) {
      trigger3 = false;
    }
  }
}

void setup() {
  Serial.begin(115200);
  delay(300);
  Serial.println("\n=== BOOT START ===");

  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW);

  // I2C start
  Wire.begin();
  Wire.setClock(100000); // 안정

  scanI2C(); //  if MPU/MAX/MLX are visible

  // MPU wake
  Wire.beginTransmission(MPU_addr);
  Wire.write(0x6B);
  Wire.write(0);
  Wire.endTransmission(true);
  Serial.println("✅ MPU wake command sent");

  // WiFi (timeout)
  Serial.println("Connecting WiFi...");
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  unsigned long start = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - start < 15000) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("✅ WiFi connected");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("❌ WiFi not connected (Firebase will fail)");
  }

  // Firebase
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  auth.user.email = "esp@gmail.com";
  auth.user.password = "12345678";
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  Serial.println("🔥 Firebase begin done");

  // MAX30102
  maxOk = particleSensor.begin(Wire, I2C_SPEED_STANDARD);
  if (maxOk) {
    particleSensor.setup(100, 2, 2, 100, 411, 16384);
    particleSensor.setPulseAmplitudeGreen(0);
    Serial.println("✅ MAX30102 ready");
  } else {
    Serial.println("❌ MAX30102 not found");
  }

  // MLX
  mlxOk = mlx.begin();
  if (mlxOk) Serial.println("✅ MLX90614 ready");
  else Serial.println("❌ MLX90614 not found");

  Serial.println("=== BOOT END ===");
}

void loop() {
  updateBuzzer();

  if (millis() - lastHeartbeat > 2000) {
    lastHeartbeat = millis();
    Serial.println("...loop alive...");
  }

  // fast fall
  fallDetection();

  // confirm / 3 minute
  pollFallStatusAndHandleBuzzer();

  // sensors
  handleSensorReading();
  sendSensorData();

  delay(100); //  loop timing
}

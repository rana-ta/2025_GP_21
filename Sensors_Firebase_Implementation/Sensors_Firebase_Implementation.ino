//ESP8266 & MAX301102 & FIREBASE 
#include <MAX30105.h>
#include <heartRate.h>
#include <spo2_algorithm.h>
#include <Firebase_ESP_Client.h>
#include <Wire.h>
#undef I2C_BUFFER_LENGTH
#undef BUFFER_SIZE
#include "spo2_algorithm.h"
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Adafruit_MLX90614.h>

// Wi-Fi details
#define WIFI_SSID     "Rana"
#define WIFI_PASSWORD "rana2003"

// Firebase Configuration
#define API_KEY "AIzaSyB8qVAcLPsMS2tLEonGFsw7Yz8VFF9mtBo"
#define DATABASE_URL "https://moeenapp-9a886-default-rtdb.firebaseio.com/"


// Firebase objects
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// OLED Configuration 
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
#define SCREEN_ADDRESS 0x3C

// MAX30102 
#define SDA_PIN D2
#define SCL_PIN D1

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

MAX30105 particleSensor;

// Temperature MLX90614
#define EMISSIVITY_SKIN 0.98
#define KELVIN_OFFSET 273.15
#define CORE_TEMP_OFFSET 2.0  
Adafruit_MLX90614 mlx = Adafruit_MLX90614();

// Buffers
#define BUFFER_SIZE 80
uint32_t irBuffer[BUFFER_SIZE];
uint32_t redBuffer[BUFFER_SIZE];

// Results
int32_t spo2;
int8_t validSPO2;
int32_t heartRate;
int8_t validHeartRate;

float smoothHR = 0;
float smoothSpO2 = 0;
float estimatedTemp = 0;

bool fingerOff = false;

unsigned long previousMillis = 0;    
const unsigned long interval = 5000; 

// Sending to firebase 
void handleFirebase() {
  if(millis() - previousMillis < interval){
    return;
  }
  previousMillis = millis();

  if(smoothHR < 50 || smoothHR > 200){
    return;
  }

  FirebaseJson json;

// Create a JSON object with the data
json.set("heartRate", (int)smoothHR);
json.set("spo2", (int)smoothSpO2);
json.set("ir", irBuffer[BUFFER_SIZE - 1]);
json.set("red", redBuffer[BUFFER_SIZE - 1]);
json.set("status", fingerOff ? "not connected" : "connected");
json.set("temperature", estimatedTemp);


// Send everything in one request
if (Firebase.RTDB.setJSON(&fbdo, "/sensorData", &json)) {
  Serial.println("✅ Data sent successfully!");
} else {
  Serial.println("❌ Firebase send failed: " + fbdo.errorReason());
}

  Serial.println("✅ Sent to Firebase");
}

// OLED Display 

void showOnDisplay() {
  display.clearDisplay();
  display.setTextSize(2);
  display.setCursor(0, 0);
  display.print("HR ");
  display.print((smoothHR > 40) ? (int)smoothHR : 0);

  display.setCursor(0, 35);
  display.print("O2 ");
  display.print((smoothSpO2 > 80) ? (int)smoothSpO2 : 0);
  display.print("%");
  display.display();

  display.setCursor(0, 40);
  display.print("Temp: ");
  display.print(estimatedTemp, 1);
  display.print("C");
}

// handle Sensor Reading 

void handleSensorReading() {
  // Read sensor buffer
  for (int i = 0; i < BUFFER_SIZE; i++) {
    while (!particleSensor.available()) particleSensor.check();
    redBuffer[i] = particleSensor.getRed();
    irBuffer[i] = particleSensor.getIR();
    particleSensor.nextSample();
  }
  // Compute HR & SpO2
  maxim_heart_rate_and_oxygen_saturation(irBuffer, BUFFER_SIZE, redBuffer,
                                         &spo2, &validSPO2, &heartRate, &validHeartRate);
 fingerOff = (particleSensor.getIR() < 25000);
  if (fingerOff) {
    smoothHR = 0;
    smoothSpO2 = 0;
    validHeartRate = 0;
    validSPO2 = 0;
    Serial.println("No finger detected.");
  } else {
    if (validHeartRate && heartRate > 40 && heartRate < 130)
      smoothHR = 0.8 * smoothHR + 0.2 * heartRate;

    if (validSPO2 && spo2 > 80 && spo2 <= 100)
      smoothSpO2 = 0.7 * smoothSpO2 + 0.3 * spo2;
  }
// MLX90614 Temperature 
  float T_object_raw_C = mlx.readObjectTempC();
  float T_ambient_C = mlx.readAmbientTempC();

  float T_object_raw_K = T_object_raw_C + KELVIN_OFFSET;
  float T_ambient_K = T_ambient_C + KELVIN_OFFSET;

  float T_object_true_K_pow4 =
      (pow(T_object_raw_K, 4.0) - pow(T_ambient_K, 4.0)) / EMISSIVITY_SKIN + pow(T_ambient_K, 4.0);
  float T_object_corrected_K = pow(T_object_true_K_pow4, 0.25);
  float T_object_corrected_C = T_object_corrected_K - KELVIN_OFFSET;
  estimatedTemp = T_object_corrected_C + CORE_TEMP_OFFSET;
}

void setup() {
  Serial.begin(115200);
  Wire.begin(SDA_PIN, SCL_PIN);

  if (!display.begin(SSD1306_SWITCHCAPVCC, SCREEN_ADDRESS)) {
    Serial.println("OLED failed");
    while (1)
      ;
  }

  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.println("Connecting WiFi...");
  display.display();

  // Wi-Fi connection
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\n✅ WiFi connected!");

  // Firebase Setup 
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  //enable anonymous login
  auth.user.email = "esp@gmail.com";
  auth.user.password = "12345678";

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  Serial.println("🔥 Firebase Connected!");


  if (!particleSensor.begin(Wire, I2C_SPEED_STANDARD)) {
    Serial.println("MAX30102 not found");
    while (1)
      ;
  }

  particleSensor.setup(100, 2, 2, 100, 411, 16384);
  particleSensor.setPulseAmplitudeGreen(0);

  // MLX90614 setup
  if (!mlx.begin()) {
    Serial.println("❌ MLX90614 not found!");
    while (1);
  }
  display.clearDisplay();
  display.setCursor(0, 0);
  display.println("Pulse Sensor Ready");
  display.display();
  delay(1000);
}


void loop() {
  
  handleSensorReading();
  showOnDisplay();
  handleFirebase();

  delay(300);
}

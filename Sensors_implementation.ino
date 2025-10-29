#include <Wire.h>
#include "MAX30105.h"
#include "spo2_algorithm.h"
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
#define SCREEN_ADDRESS 0x3C

#define SDA_PIN 21
#define SCL_PIN 22

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);
MAX30105 particleSensor;

// Buffers
#define BUFFER_SIZE 80  
uint32_t irBuffer[BUFFER_SIZE];
uint32_t redBuffer[BUFFER_SIZE];

// Calculated values
int32_t spo2;
int8_t validSPO2;
int32_t heartRate;
int8_t validHeartRate;

float smoothHR = 0;
float smoothSpO2 = 0;

void setup() {
  Serial.begin(115200);
  Wire.begin(SDA_PIN, SCL_PIN);

  if (!display.begin(SSD1306_SWITCHCAPVCC, SCREEN_ADDRESS)) {
    Serial.println("OLED failed");
    while (1);
  }

  if (!particleSensor.begin(Wire, I2C_SPEED_STANDARD)) {
    Serial.println("MAX30102 not found");
    while (1);
  }

  //Sensor setup
  byte ledBrightness = 100;  // keep moderate light
  byte sampleAverage = 2;   // faster response
  byte ledMode = 2;         // red + IR
  int sampleRate = 100;     // faster sampling
  int pulseWidth = 411;
  int adcRange = 16384;

  particleSensor.setup(ledBrightness, sampleAverage, ledMode, sampleRate, pulseWidth, adcRange);
  particleSensor.setPulseAmplitudeGreen(0);

  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.println("Pulse Oximeter Ready");
  display.display();
  delay(1500);
}

void loop() {
  // Fill buffer
  for (int i = 0; i < BUFFER_SIZE; i++) {
    while (!particleSensor.available()) { particleSensor.check(); }
    redBuffer[i] = particleSensor.getRed();
    irBuffer[i]  = particleSensor.getIR();
    particleSensor.nextSample();
  }

// Compute new values immediately
  maxim_heart_rate_and_oxygen_saturation(
    irBuffer, BUFFER_SIZE, redBuffer,
    &spo2, &validSPO2, &heartRate, &validHeartRate);


  if (heartRate > 180 || heartRate < 30) validHeartRate = 0;

  // Detect finger removal instantly
  bool fingerOff = (particleSensor.getIR() < 25000);  

  if (fingerOff) {
    // reset readings instantly when no finger detected
    smoothHR = 0;
    smoothSpO2 = 0;
    validHeartRate = 0;
    validSPO2 = 0;
    Serial.println("No finger detected.");
  } else {
  // Normal smoothing when finger is present
  if (validHeartRate && heartRate > 40 && heartRate < 130)
  smoothHR = 0.8 * smoothHR + 0.2 * heartRate;

  if (validSPO2 && spo2 > 80 && spo2 <= 100)
  smoothSpO2 = 0.7 * smoothSpO2 + 0.3 * spo2;
  }


  // Display results
  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.println("Pulse Oximeter");

  display.setTextSize(2);
  display.setCursor(0, 20);
  display.print("HR: ");
  if (smoothHR > 40) display.print((int)smoothHR);
  else display.print("--");

  display.setCursor(0, 45);
  display.print("SpO2: ");
  if (smoothSpO2 > 80) display.print((int)smoothSpO2);
  else display.print("--");
  display.print("%");
  display.display();

  // Serial output for debugging
  Serial.print("IR: ");
  Serial.print(irBuffer[BUFFER_SIZE - 1]);
  Serial.print(" | RED: ");
  Serial.print(redBuffer[BUFFER_SIZE - 1]);
  Serial.print(" | HR: ");
  Serial.print((int)smoothHR);
  Serial.print(" | SpO2: ");
  Serial.println((int)smoothSpO2);

  delay(100); // update the results
}
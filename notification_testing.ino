#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <BLE2902.h> 

#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

BLECharacteristic* pCharacteristic;

void setup() {
  Serial.begin(115200);
  Serial.println("Starting BLE Glucose Monitor...");

  BLEDevice::init("ESP32-GlucoseMonitor");
  delay(2000);

  BLEAddress mac = BLEDevice::getAddress();
  Serial.print("ESP32 MAC Address: ");
  Serial.println(mac.toString().c_str());

  BLEServer *pServer = BLEDevice::createServer();
  BLEService *pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ |
                      BLECharacteristic::PROPERTY_NOTIFY
                    );

  //BLE Client Characteristic Configuration Descriptor
  pCharacteristic->addDescriptor(new BLE2902());

  pCharacteristic->setValue("Init");
  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.println("BLE ready. Waiting for client to subscribe...");
}

void loop() {
  delay(60000); // wait 60s

  int glucose = random(70, 180);
  char buf[10];
  snprintf(buf, sizeof(buf), "%d", glucose);

  Serial.print("Sending glucose level: ");
  Serial.println(buf);

  pCharacteristic->setValue(buf);
  pCharacteristic->notify(); // Notify connected subscribers
}

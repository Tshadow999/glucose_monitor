# Mobile app

A flutter project using BLE to comminicate with a ESP32, which in turn gets data from an AFE4420.
This data is send to the cloud, where a Machine learning model will output a single glucose reading.

## Features:
- Daily graph, average
- Notifications if thresholds have been reached.
- Machine learning model in cloud
- Unit changer (mmol/L or mg/dL)
- Light and dark modes

## Usage:
    if you have an android device attached:
    flutter run
    otherwise: 
    flutter build apk --debug
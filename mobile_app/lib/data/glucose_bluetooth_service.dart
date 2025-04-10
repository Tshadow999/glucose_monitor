import 'dart:async';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ScannedDevice {
  final BluetoothDevice device;
  final int rssi;

  ScannedDevice({required this.device, required this.rssi});
}

class GlucoseReading {
  final double value; // in mg/dL
  final DateTime timestamp;

  GlucoseReading({required this.value, required this.timestamp});
}

// Connecting to the esp
final String ESP_SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
final String ESP_CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

class GlucoseBluetoothService with ChangeNotifier {
  // Singleton pattern
  static final GlucoseBluetoothService _instance =
      GlucoseBluetoothService._internal();
  factory GlucoseBluetoothService() => _instance;
  GlucoseBluetoothService._internal();

  // Updating scanned devices
  final StreamController<List<ScannedDevice>> _deviceStreamController =
      StreamController<List<ScannedDevice>>.broadcast();
  Stream<List<ScannedDevice>> get deviceStream =>
      _deviceStreamController.stream;

  final Map<String, ScannedDevice> _scannedDevices = {};

  // Device and connection state
  BluetoothDevice? _connectedDevice;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  // Initialize the service
  Future<void> initialize(BuildContext context) async {
    FlutterBluePlus.setLogLevel(LogLevel.warning, color: false);
    bool permissions = await requestPermissions();
    if (!permissions) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bluetooth permissions are required")),
        );
      }
      return;
    }

    var subscription = FlutterBluePlus.adapterState.listen((
      BluetoothAdapterState state,
    ) {
      if (state == BluetoothAdapterState.on) {
        //yay
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Bluetooth state is ${state.toString().split(".").last}",
            ),
          ),
        );
      }
    });

    subscription.cancel();
  }

  Future<void> stopScanning() async {
    FlutterBluePlus.stopScan();
    await Future.delayed(Duration(seconds: 1));
  }

  Future<void> scanDevices(
    BuildContext context, {
    int timeoutSeconds = 10,
  }) async {
    _scannedDevices.clear();

    await FlutterBluePlus.startScan(timeout: Duration(seconds: timeoutSeconds));

    var subscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        if (results.isNotEmpty) {
          for (ScanResult r in results) {
            final id = r.device.remoteId.str;
            _scannedDevices[id] = ScannedDevice(device: r.device, rssi: r.rssi);
          }
        }

        final sortedDevices =
            _scannedDevices.values.toList()
              ..sort((a, b) => b.rssi.compareTo(a.rssi));

        _deviceStreamController.add(sortedDevices);
      },
      onError: (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      },
    );

    FlutterBluePlus.cancelWhenScanComplete(subscription);
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses =
          await [
            Permission.bluetooth,
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.location,
          ].request();

      return statuses.values.every((status) => status.isGranted);
    }

    return true; // iOS handles permissions differently
  }
}

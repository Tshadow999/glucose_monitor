import 'dart:async';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class GlucoseReading {
  final double value; // in mg/dL
  final DateTime timestamp;

  GlucoseReading({required this.value, required this.timestamp});
}

class GlucoseBluetoothService with ChangeNotifier {
  // Singleton pattern
  static final GlucoseBluetoothService _instance =
      GlucoseBluetoothService._internal();
  factory GlucoseBluetoothService() => _instance;
  GlucoseBluetoothService._internal();

  final StreamController<List<BluetoothDevice>> _deviceStreamController =
      StreamController<List<BluetoothDevice>>.broadcast();
  Stream<List<BluetoothDevice>> get deviceStream =>
      _deviceStreamController.stream;

  // Device and connection state
  BluetoothDevice? _connectedDevice;

  BluetoothDevice? get connectedDevice => _connectedDevice;

  // Initialize the service
  Future<void> initialize(BuildContext context) async {
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
    List<BluetoothDevice> discoveredDevices = [];

    await FlutterBluePlus.startScan(timeout: Duration(seconds: timeoutSeconds));

    var subscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        if (results.isNotEmpty) {
          for (ScanResult r in results) {
            if (!discoveredDevices.contains(r.device)) {
              discoveredDevices.add(r.device);
            }
          }
        }

        _deviceStreamController.add(discoveredDevices);
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

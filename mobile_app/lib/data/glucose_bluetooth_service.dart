import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:sugar_daddy/data/local_storage.dart';

class ScannedDevice {
  final BluetoothDevice device;
  final int rssi;

  ScannedDevice({required this.device, required this.rssi});
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

  final StreamController<GlucoseReading> readingStreamController =
    StreamController<GlucoseReading>.broadcast();

Stream<GlucoseReading> get glucoseReadings => readingStreamController.stream;

StreamSubscription<List<int>>? notificationSubscription;

  final StreamController<List<ScannedDevice>> _deviceStreamController =
      StreamController<List<ScannedDevice>>.broadcast();
  Stream<List<ScannedDevice>> get deviceStream =>
      _deviceStreamController.stream;

  final Map<String, ScannedDevice> _scannedDevices = {};

  BluetoothDevice? _connectedDevice;

  Future<void> initialize(BuildContext context) async {

    // We already have a device, no need to init again
    if (_connectedDevice != null) {
      return;
    }

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

  List<BluetoothDevice> connectedDevices() {
    return FlutterBluePlus.connectedDevices;
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await stopScanning();

      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;

      List<BluetoothService> services = await device.discoverServices();

      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == ESP_SERVICE_UUID.toLowerCase()) {
          for (BluetoothCharacteristic c in service.characteristics) {
            if (c.uuid.toString().toLowerCase() == ESP_CHAR_UUID.toLowerCase()) {
              if (c.properties.notify) {
                await c.setNotifyValue(true);

                // Cancel old subscription if exists
                await notificationSubscription?.cancel();

                notificationSubscription = c.lastValueStream.listen((value) async {
                final notification = String.fromCharCodes(value);

                final regex = RegExp(r"\s*(\d+):PD1:\s*(\d+), PD2:\s*(\d+)");
                final match = regex.firstMatch(notification);

                if (match != null && match.groupCount >= 3) {
                  try {
                    final timestamp = int.parse(match.group(1)!);
                    final pd1 = int.parse(match.group(2)!);
                    final pd2 = int.parse(match.group(3)!);

                    final reading = GlucoseReading(
                      value: pd1.toDouble(), // or pd2, depending on which you want
                      timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
                    );

                    readingStreamController.add(reading);

                    final csvLine = '${reading.timestamp.toIso8601String()},$pd1,$pd2\n';
                    final dir = await getTemporaryDirectory();
                    final file = File('${dir.path}/readings.csv');
                    await file.writeAsString(csvLine, mode: FileMode.append);

                    print("Saved: $csvLine");
                  } catch (e) {
                    print("Failed to parse or save data: $e");
                  }
                } else {
                  print("Failed to match notification: $notification");
                }
              });

                return;
              }
            }
          }
        }
      }

      throw Exception("Target service/characteristic not found");

    } catch (e) {
      print("Connection failed: $e");
      rethrow;
    }
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

  Future<void> disconnect() async {
    await notificationSubscription?.cancel();
    notificationSubscription = null;

    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (_) {}
      _connectedDevice = null;
    }
  }
}

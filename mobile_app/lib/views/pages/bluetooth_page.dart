import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sugar_daddy/data/glucose_bluetooth_service.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  bool isBluetoothOn = false;
  BluetoothDevice? _connectedDevice;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    checkBluetoothState();
    initBluetooth();
  }

  @override
  Widget build(BuildContext context) {
    return isBluetoothOn ? deviceList() : bluetoothButton();
  }

  Widget deviceList() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: RefreshIndicator(
        onRefresh: refreshScan,
        child: StreamBuilder<List<ScannedDevice>>(
          stream: GlucoseBluetoothService().deviceStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData && snapshot.data != null) {
              List<ScannedDevice> devices = snapshot.data!;
              return ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  ScannedDevice scan = devices[index];
                  return showAvailableDeviceTile(scan, context);
                },
              );
            } else {
              return Center(child: Text('No devices found.'));
            }
          },
        ),
      ),
    );
  }

  Widget bluetoothButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Bluetooth is turned off', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: turnBluetoothOn,
            icon: const Icon(Icons.bluetooth),
            label: const Text('Turn On Bluetooth'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void checkBluetoothState() {
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      setState(() {
        isBluetoothOn = state == BluetoothAdapterState.on;
      });
    });
  }

  void initBluetooth() async {
    await GlucoseBluetoothService().initialize(context);
    if (!mounted) return;
    if (isBluetoothOn) {
      await GlucoseBluetoothService().scanDevices(context);
    }
  }

  Future<void> turnBluetoothOn() async {
    try {
      await FlutterBluePlus.turnOn();

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      await GlucoseBluetoothService().scanDevices(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to turn on Bluetooth: $e')),
      );
    }
  }

  Widget showAvailableDeviceTile(ScannedDevice scan, BuildContext context) {
    bool isConnected =
        _connectedDevice != null &&
        _connectedDevice!.remoteId == scan.device.remoteId;

    // Dont list devices without a name
    if (scan.device.platformName.toString().isEmpty) return Container();

    return Card(
      color:
          isConnected
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.surfaceContainer,
      child: ListTile(
        leading: Icon(
          isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
          color: isConnected ? Colors.blue : null,
        ),
        title: Text(
          scan.device.platformName.toString().isNotEmpty
              ? scan.device.platformName.toString()
              : "---",
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("MAC: ${scan.device.remoteId}"),
            Text("RSSI:  ${scan.rssi}"),
          ],
        ),
        onTap: () {
          if (isConnected || _isConnecting) return;

          handleDeviceTileTap(scan.device);
        },
      ),
    );
  }

  Future<void> refreshScan() async {
    if (!isBluetoothOn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please turn on Bluetooth first')),
      );
      return;
    }
    await GlucoseBluetoothService().stopScanning();
    if (!mounted) return;
    await GlucoseBluetoothService().scanDevices(context);
  }

  Future<void> handleDeviceTileTap(BluetoothDevice device) async {
    try {
      setState(() {
        _isConnecting = true;
      });

      // Stop scanning before connecting
      await GlucoseBluetoothService().stopScanning();

      // Connect to the device
      await device.connect(timeout: const Duration(seconds: 15));

      setState(() {
        _connectedDevice = device;
        _isConnecting = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${device.platformName}')),
      );

      // Immediately read data after connecting
      readDataFromDevice(device);
    } catch (e) {
      setState(() {
        _isConnecting = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
    }
  }

  Future<void> readDataFromDevice(BluetoothDevice device) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Discovering services...')));

      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      bool foundService = false;

      for (BluetoothService service in services) {
        debugPrint('Found service: ${service.uuid}');

        // Check if this is our target service
        if (service.uuid.toString().toLowerCase() ==
            ESP_SERVICE_UUID.toLowerCase()) {
          foundService = true;

          for (BluetoothCharacteristic c in service.characteristics) {
            // Check if this is our target characteristic
            if (c.uuid.toString().toLowerCase() ==
                ESP_CHAR_UUID.toLowerCase()) {
              // Set up notifications if supported
              if (c.properties.notify) {
                await c.setNotifyValue(true);
                // Here is where data is being read
                c.lastValueStream.listen((value) async {
                  String notification = String.fromCharCodes(value);

                  // thank you gpt
                  final regex = RegExp(
                    r'ppg1:\s*([\d.]+),\s*ppg2:\s*([\d.]+),\s*ppg3\s*([\d.]+)',
                  );
                  final match = regex.firstMatch(notification);

                  if (match != null) {
                    final float1 = match.group(1);
                    final float2 = match.group(2);
                    final float3 = match.group(3);

                    final csvLine = '$float1,$float2,$float3\n';

                    final dir = await getTemporaryDirectory();
                    final file = File('${dir.path}/readings.csv');

                    // Append line
                    await file.writeAsString(csvLine, mode: FileMode.append);

                    if (!mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Saved: $csvLine')));
                  } else {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to parse: $notification')),
                    );
                  }

                  /* 
                  // Only for debug
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('New reading: $notification')),
                  );
                  */
                });

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications enabled')),
                );
              }
            }
          }
        }
      }

      if (!foundService && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Target service not found on this device'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error reading data: $e')));
    }
  }
}

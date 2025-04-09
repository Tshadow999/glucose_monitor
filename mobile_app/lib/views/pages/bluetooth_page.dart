import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:sugar_daddy/data/glucose_bluetooth_service.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  @override
  void initState() {
    super.initState();
    initBluetooth();
  }

  void initBluetooth() async {
    await GlucoseBluetoothService().initialize(context);
    if (!mounted) return;
    await GlucoseBluetoothService().scanDevices(context);
  }

  @override
  Widget build(BuildContext context) {
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
                  return showAvailableDeviceTile(scan);
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

  Widget showAvailableDeviceTile(ScannedDevice scan) {
    return  ListTile(
      title: Text(scan.device.platformName.toString()),
      subtitle: Row(
        children: [
          Text("MAC: ${scan.device.remoteId}"),
          Text("RSSI:  ${scan.rssi}"),
        ],
      ),
      onTap: () async {
        try {
          await scan.device.connect();

          if(!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connected to ${scan.device.remoteId}')),
          );

          List<BluetoothService> services = await scan.device.discoverServices();
          for (BluetoothService service in services) {
            debugPrint('Found service: ${service.uuid}');
            if (service.uuid.toString().toLowerCase() == ESP_SERVICE_UUID) {
              for (BluetoothCharacteristic c in service.characteristics) {
                if (c.uuid.toString().toLowerCase() == ESP_CHAR_UUID) {
                  if (c.properties.read) {
                    List<int> value = await c.read();
                    String result = String.fromCharCodes(value);
                    print("Read from ESP: $result");

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("ESP Data: $result")),
                      );
                    }
                  }

                  await c.setNotifyValue(true);
                    c.lastValueStream.listen((value) {
                      String notification = String.fromCharCodes(value);
                      debugPrint('Notification: $notification');
                    }
                  );
                }
              }
            }
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $e')),
          );
        }
      },
    );
  }

  Future<void> refreshScan() async {
    await GlucoseBluetoothService().stopScanning();
    if (!mounted) return;
    await GlucoseBluetoothService().scanDevices(context);
  }
}

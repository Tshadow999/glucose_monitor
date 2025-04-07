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
        child: StreamBuilder<List<BluetoothDevice>>(
          stream: GlucoseBluetoothService().deviceStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData && snapshot.data != null) {
              List<BluetoothDevice> devices = snapshot.data!;
              return ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  BluetoothDevice device = devices[index];
                  return ListTile(
                    title: Text(device.platformName.toString()),
                    subtitle: Text(device.remoteId.toString()),
                    onTap: () {
                      // Handle device tap, maybe connect to the selected device
                    },
                  );
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

  Future<void> refreshScan() async {
    await GlucoseBluetoothService().stopScanning();
    if (!mounted) return;
    await GlucoseBluetoothService().scanDevices(context);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
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
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    checkBluetoothState();
    initBluetooth();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_connectedDevice == null && isBluetoothOn) {
      _checkAlreadyConnectedDevice();
      if (!_isScanning) {
        refreshScan();
      }
    }
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

              // Ensure connected device is always shown at the top, even if not in scan results
              if (_connectedDevice != null &&
                  !devices.any(
                    (d) => d.device.remoteId == _connectedDevice!.remoteId,
                  )) {
                devices.insert(
                  0,
                  ScannedDevice(device: _connectedDevice!, rssi: 0),
                );
              }

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
      if (isBluetoothOn) {
        _checkAlreadyConnectedDevice();
        if (!_isScanning) {
          refreshScan();
        }
      }
    });
  }

  void initBluetooth() async {
    // No need to init if already have a connection
    if (_connectedDevice != null) {
      _isConnecting = false;
      _isScanning = false;
      isBluetoothOn = true;
      return;
    }

    // needs to happen
    await Future.delayed(Duration(seconds: 1));

    if (!mounted) return;
    await GlucoseBluetoothService().initialize(context);

    // Start scanning for devices if no device is connected.
    if (_connectedDevice == null && isBluetoothOn && mounted) {
      await GlucoseBluetoothService().scanDevices(context);
      setState(() {
        _isScanning = true;
      });
    }
  }

  void _checkAlreadyConnectedDevice() async {
    List<BluetoothDevice> connectedDevices =
        GlucoseBluetoothService().connectedDevices();
    if (connectedDevices.isNotEmpty) {
      BluetoothDevice device = connectedDevices.first;

      setState(() {
        _connectedDevice = device;
      });

      // Only connect if not already connected
      final connectionState = await device.connectionState.first;
      if (connectionState != BluetoothConnectionState.connected) {
        await GlucoseBluetoothService().connectToDevice(device);
      }
    }
  }

  Future<void> turnBluetoothOn() async {
    try {
      await FlutterBluePlus.turnOn();

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      await GlucoseBluetoothService().scanDevices(context);
      setState(() {
        _isScanning = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to turn on Bluetooth: $e')),
      );
    }
  }

  bool _once = false;

  Widget showAvailableDeviceTile(ScannedDevice scan, BuildContext context) {
    bool isConnected = _connectedDevice?.remoteId == scan.device.remoteId;

    if (scan.device.platformName.toString().isEmpty) return Container();

    if (_connectedDevice != null && !_once) {
      _once = true;

      return Card(
        color: Theme.of(context).colorScheme.onPrimary,
        child: ListTile(
          leading: Icon(Icons.bluetooth_connected, color: Colors.blue),
          title: Text(scan.device.platformName.toString()),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("MAC: ${_connectedDevice!.remoteId}"),
              Text("Connected"),
            ],
          ),
          onTap: () {
            if (isConnected || _isConnecting) return;

            handleDeviceTileTap(_connectedDevice!);
          },
        ),
      );
    } else {
      return Card(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: ListTile(
          leading: Icon(Icons.bluetooth, color: null),
          title: Text(scan.device.platformName.toString()),
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
  }

  Future<void> refreshScan() async {
    if (!isBluetoothOn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please turn on Bluetooth first')),
      );
      return;
    }

    if (_isScanning) {
      await GlucoseBluetoothService().stopScanning();
      setState(() {
        _isScanning = false;
      });
    }

    if (!mounted) return;

    await GlucoseBluetoothService().scanDevices(context);
    setState(() {
      _isScanning = true;
    });
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

      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.connected) {
          setState(() {
            _connectedDevice = device;
            _isConnecting = false;
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connected to ${device.platformName}')),
          );

          // Immediately read data after connecting
          GlucoseBluetoothService().connectToDevice(device);
        } else if (state == BluetoothConnectionState.disconnected) {
          setState(() {
            _connectedDevice = null;
            _isConnecting = false;
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Disconnected from ${device.platformName}')),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
    }
  }
}

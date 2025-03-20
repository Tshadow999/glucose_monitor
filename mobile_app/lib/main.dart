import 'package:flutter/material.dart';
import 'package:GlucoMonitor/data/constants.dart';
import 'package:GlucoMonitor/data/notification_service.dart';
import 'package:GlucoMonitor/views/pages/login_page.dart';
import 'package:GlucoMonitor/data/notifiers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    initPreferences();
    super.initState();
  }

  Future<void> initPreferences() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool? themeMode = prefs.getBool(CustomConstants.themeModePrefKey);
    darkModeNotifier.value = themeMode ?? false;

    final bool? glucoseUnit = prefs.getBool(CustomConstants.glucoseUnitPrefKey);
    glucoseUnitNotifier.value = glucoseUnit ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: darkModeNotifier,
      builder: (context, isDarkMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Continuous Glucose Monitoring App',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: isDarkMode ? Brightness.dark : Brightness.light,
            ),
          ),
          home: LoginPage(),
        );
      },
    );
  }
}

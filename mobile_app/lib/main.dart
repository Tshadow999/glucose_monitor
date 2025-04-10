import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sugar_daddy/data/database_service.dart';
import 'package:sugar_daddy/data/constants.dart';
import 'package:sugar_daddy/data/local_storage.dart';
import 'package:sugar_daddy/data/notification_service.dart';
import 'package:sugar_daddy/views/pages/login_page.dart';
import 'package:sugar_daddy/data/notifiers.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().init();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);

  GlucoseReadingService().initHive();

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

    getDocID();
  }

  void getDocID() async {
    await DatabaseService.updateDocumentIds("user_data");
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
              seedColor: Color.from(
                red: 0.67,
                green: 0.51,
                blue: 0.8,
                alpha: 1.0,
              ),
              brightness: isDarkMode ? Brightness.dark : Brightness.light,
            ),
          ),
          home: LoginPage(),
        );
      },
    );
  }
}

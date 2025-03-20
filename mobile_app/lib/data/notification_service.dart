import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  /// Singleton in dart
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final notificationPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Will init the notifications plugin
  /// wont do anything if initialized already
  Future<void> init() async {
    if (_isInitialized) return;

    // init timezone
    tz.initializeTimeZones();
    final String currentTZ = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTZ));

    // prep android
    const initSettingsAndroid = AndroidInitializationSettings(
      //TODO Make logo for app and change below
      "@mipmap/ic_launcher",
    );

    // prep iOS
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // finally init the plugin
    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    await notificationPlugin.initialize(initSettings);
    // Explicitly request notification permissions for Android 13+
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        await Permission.notification.request();
      }
    }

    _isInitialized = true;
  }

  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        "Threshold",
        "Threshold",
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  Future<void> show({int id = 0, String? title, String? body}) {
    return notificationPlugin.show(id, title, body, notificationDetails());
  }

  /// hour: 0-23
  /// minute: 0-59
  Future<void> schedule({
    int id = 1,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    await notificationPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      notificationDetails(),

      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,

      // For repeating daily notifications:
      // matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelAll() async {
    await notificationPlugin.cancelAll();
  }
}

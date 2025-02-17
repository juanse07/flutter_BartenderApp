import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final _uuid = Uuid();
final Set<String> _recentNotifications = {};

class NotificationService {
  static const platform =
      MethodChannel('online.denverbartenders.IamDenverBartender/push');
  final String baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:8888';
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  Future<String?> getAPNsToken() async {
    try {
      final String? token = await platform.invokeMethod('getAPNsToken');
      print('APNs Device Token: $token');
      return token;
    } on PlatformException catch (e) {
      print('Failed to get token: ${e.message}');
      return null;
    }
  }

  Future<void> _initNotifications() async {
    // Request notification permissions for Android (API 33+) and iOS
    await _requestPermissions();

    // Android initialization settings
    const initializationSettingsAndroid =
        AndroidInitializationSettings('ic_launcher');

    // iOS initialization settings
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBanner: true,
    );

    // Combine Android and iOS settings
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        print('🔔 Notification tapped: ${details.payload}');
      },
    );

    print(' Notifications initialized');
  }

  Future<void> _requestPermissions() async {
    if (await Permission.notification.isGranted) {
      print('Notification permission already granted');
    } else {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        print('Notification permission granted');
      } else {
        print('Notification permission denied');
      }
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    try {
      // Create a unique key for this notification
      final notificationKey = '$title$body${DateTime.now().minute}';

      // Check if we've shown this notification in the last minute
      if (_recentNotifications.contains(notificationKey)) {
        print('🚫 Duplicate notification prevented: $title');
        return;
      }

      print('🔔 Attempting to show notification: $title - $body');
      const androidDetails = AndroidNotificationDetails(
        'channel_id',
        'channel_name',
        channelDescription: 'channel_description',
        importance: Importance.max,
        priority: Priority.high,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBanner: true,
        sound: 'default',
        threadIdentifier: 'thread_id',
      );
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        DateTime.now().millisecond,
        title,
        body,
        notificationDetails,
        payload: 'payload',
      );

      // Add to recent notifications
      _recentNotifications.add(notificationKey);

      // Remove from set after 1 minute
      Future.delayed(const Duration(minutes: 1), () {
        _recentNotifications.remove(notificationKey);
      });

      print('✅ Notification shown successfully');
    } catch (e) {
      print('❌ Error showing notification: $e');
    }
  }

  Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');

    if (deviceId == null) {
      deviceId = _uuid.v4();
      await prefs.setString('device_id', deviceId);
    }

    return deviceId;
  }

  Future<void> registerApnsToken(String token) async {
    final deviceId = await getOrCreateDeviceId();
    final url = Uri.parse("$baseUrl/register-device");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": deviceId, "deviceToken": token}),
    );
    if (response.statusCode == 200) {
      print("APNs token registered on server.");
    } else {
      print("Error registering token: ${response.body}");
    }
  }

  Future<void> printAPNsToken() async {
    try {
      final String? token = await getAPNsToken();
      print('\n==========================================');
      print('APNs Device Token for Backend Configuration:');
      print(token);
      print('==========================================\n');

      // Store token in SharedPreferences and register with server
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('apns_token', token);
        await registerApnsToken(token);
      }
    } catch (e) {
      print('Error getting APNs token: $e');
    }
  }

  Future<void> initialize() async {
    try {
      // Initialize notifications first
      await _initNotifications();
      // Then get the token
      await printAPNsToken();
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }
}

// class NotificationService {
//   final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
//   static final NotificationService _instance = NotificationService._internal();

//   factory NotificationService() => _instance;

//   NotificationService._internal() {
//     _initNotifications();
//   }

//   Future<void> _initNotifications() async {
//     const initializationSettingsIOS = DarwinInitializationSettings(
//       requestSoundPermission: true,
//       requestBadgePermission: true,
//       requestAlertPermission: true,
//       defaultPresentAlert: true,
//       defaultPresentSound: true,
//       defaultPresentBanner: true,
//     );

//     const initializationSettings = InitializationSettings(
//       iOS: initializationSettingsIOS,
//     );

//     await _notifications.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: (details) {
//         print('🔔 Notification tapped: ${details.payload}');
//       },
//     );

//     print('📱 Notifications initialized');
//   }

//   Future<void> showNotification({
//     required String title,
//     required String body,
//   }) async {
//     try {
//       print('🔔 Attempting to show notification: $title - $body');
      
//       const notificationDetails = NotificationDetails(
//         iOS: DarwinNotificationDetails(
//           presentAlert: true,
//           presentSound: true,
//           presentBanner: true,
//           sound: 'default',
         
//           threadIdentifier: 'thread_id', // Group notifications by thread
//         ),
//       );

//       await _notifications.show(
//         DateTime.now().millisecond,
//         title,
//         body,
//         notificationDetails,
//       );
      
//       print('✅ Notification shown successfully');
//     } catch (e) {
//       print('❌ Error showing notification: $e');
//     }
//   }
// }
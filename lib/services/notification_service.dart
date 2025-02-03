import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const platform = MethodChannel('com.example.bartenderCompanion/push');

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

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal() {
    _initNotifications();
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
      print('Attempting to show notification: $title - $body');
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
        threadIdentifier: 'thread_id', // Group notifications by thread
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

      print('Notification shown successfully');
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  Future<void> printAPNsToken() async {
    try {
      final String? token = await getAPNsToken();
      print('\n==========================================');
      print('APNs Device Token for Backend Configuration:');
      print(token);
      print('==========================================\n');

      // Store token in SharedPreferences
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('apns_token', token);
      }
    } catch (e) {
      print('Error getting APNs token: $e');
    }
  }

  Future<void> initialize() async {
    try {
      await _initNotifications();
      await printAPNsToken();
    } catch (e) {
      print('Error initializing notification service: $e');
      // Continue without notifications rather than crashing
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
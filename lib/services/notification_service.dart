import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';


class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal() {
    _initNotifications();
  }


Future<void> _initNotifications() async {
  // Request notification permissions for Android (API 33+) and iOS
  await _requestPermissions();

  // Android initialization settings
  const initializationSettingsAndroid = AndroidInitializationSettings('ic_launcher');

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

  print('📱 Notifications initialized');
}

Future<void> _requestPermissions() async {
  if (await Permission.notification.isGranted) {
    print('✅ Notification permission already granted');
  } else {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      print('✅ Notification permission granted');
    } else {
      print('❌ Notification permission denied');
    }
  }
}

 Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    try {
      print('🔔 Attempting to show notification: $title - $body');
      
      const notificationDetails = NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBanner: true,
          sound: 'default',
         
          threadIdentifier: 'thread_id', // Group notifications by thread
        ),
      );

      await _notifications.show(
        DateTime.now().millisecond,
        title,
        body,
        notificationDetails,
      );
      
      print('✅ Notification shown successfully');
    } catch (e) {
      print('❌ Error showing notification: $e');
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
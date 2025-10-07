import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final prefs = SharedPreferences.getInstance();
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Request permission (iOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // ✅ iOS foreground presentation options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    // Initialize flutter_local_notifications
    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // ✅ iOS init settings
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();

    // ✅ Combined init settings
    const InitializationSettings initSettings =
    InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotifications.initialize(initSettings
      // , onDidReceiveNotificationResponse: (NotificationResponse response) {
      //   final action = response.payload;
      //   _handleClickActionFromPayload(action);
      // }
    );

    // Print device token
    final token = await _messaging.getToken();
    print("FCM Token: $token");

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print("🔁 FCM Token refreshed: $newToken");
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("fcm_token", newToken);
      // TODO: Send newToken to your backend here
    });

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // When app is opened via notification (from background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // _handleClickAction(message); // commented for now
      print("Notification tapped: ${message.data}");
    });

    // Handle initial message if app was terminated
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // _handleClickAction(initialMessage); // commented for now
      print("App opened from terminated state by notification: ${initialMessage.data}");
    }
  }

  static Future<void> _showNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'] ?? 'TMS';
    final body = message.notification?.body ?? message.data['body'] ?? '';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'tms_channel',
      'TMS Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
      payload: message.data['click_action'] ?? '',
    );

    print("Foreground notification received: $title - $body");
  }

// Click action handling (currently commented)
// static void _handleClickAction(RemoteMessage message) {
//   final action = message.data['click_action'];
//   _handleClickActionFromPayload(action);
// }

// static void _handleClickActionFromPayload(String? action) {
//   switch (action) {
//     case "OPEN_APPROVE_LEAVE_SCREEN":
//       Get.toNamed("/approve-leave");
//       break;
//     case "OPEN_VIEW_LEAVE_SCREEN":
//       Get.toNamed("/view-leave");
//       break;
//     default:
//       Get.toNamed("/dashboard");
//   }
// }
}

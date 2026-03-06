import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_service.dart';
import '../dto/update_fcm_token_dto.dart';

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final prefs = SharedPreferences.getInstance();
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // ✅ Request permission (iOS/Android 13+)
    // We capture the settings to ensure we can log or handle the status if needed
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false, // Set to true if you want 'Quiet' notifications initially
    );

    print('User granted permission: ${settings.authorizationStatus}');

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

    await _localNotifications.initialize(initSettings);

    // ✅ Generate and Save device token
    // This ensures SharedPreferences has the token ready for the Login Controller
    final token = await _messaging.getToken();
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("fcm_token", token);
      print("FCM Token initialized and saved: $token");
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print("🔁 FCM Token refreshed: $newToken");

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("fcm_token", newToken);

      // Check if user is logged in before trying to update the server
      final String? userId = prefs.getString("user_id");
      final String? authToken = prefs.getString("auth_token");
      final bool isLogged = prefs.getBool("is_logged") ?? false;

      if (isLogged && userId != null && authToken != null) {
        try {
          // We need an instance of ApiService to make the call
          final api = ApiService();
          final packageInfo = await PackageInfo.fromPlatform();

          final fcmDto = UpdateFcmTokenDto(
            userId: userId,
            APPName: packageInfo.packageName,
            APPVersion: packageInfo.version.split('.').first,
            Token: newToken,
          );

          // Use the stored JWT token (with Bearer prefix)
          await api.updateFCMToken(
            userId: userId,
            dto: fcmDto,
            token: "Bearer $authToken",
          );
          print("✅ Server updated with refreshed FCM Token");
        } catch (e) {
          print("❌ Failed to update refreshed token on server: $e");
        }
      }
    });

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // When app is opened via notification (from background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification tapped: ${message.data}");
    });

    // Handle initial message if app was terminated
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
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
}
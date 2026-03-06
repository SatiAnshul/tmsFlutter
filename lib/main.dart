import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'services/fcm_service.dart';
import 'view/login/login_screen.dart';
import 'view/dashboard/dashboard_screen.dart';
import 'view/myattendance/view_attendance/view_attendance_screen.dart';
import 'view/myattendance/master_attendance/view_master_attendance_screen.dart';
import 'view/myattendance/mark_attendance/face_verification_screen.dart';
import 'view/holidays/holiday_screen.dart';
import 'view/reset_password/reset_password_screen.dart';
import 'firebase_options.dart';

//Background message handler
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background message: ${message.data}");
  // You can also show a local notification here if you want
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //await Firebase.initializeApp();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  // Initialize your FCM service
  await FcmService.init();

  final sharedPref = await SharedPreferences.getInstance();
  final bool isLogged = sharedPref.getBool("is_logged") ?? false;

  await initializeDateFormatting('en', null);

  runApp(MyApp(isLogged: isLogged));
}

class MyApp extends StatelessWidget {
  final bool isLogged;
  const MyApp({super.key, required this.isLogged});

  @override
  Widget build(BuildContext context) {
    final initialRoute = isLogged ? '/dashboard' : '/login';
    return GetMaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 4,
          titleTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
          shape:  const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(8),
            ),
          ),
          backgroundColor: Color(0xFF0894DA),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/dashboard', page: () => const DashboardScreen()),
        GetPage(name: '/myattendance/view_attendance', page: () => const ViewAttendanceScreen()),
        GetPage(name: '/myattendance/master_attendance', page: () => const ViewMasterAttendanceScreen()),
        GetPage(name: '/myattendance/mark_attendance', page: () => const FaceVerificationScreen()),
        GetPage(name: '/holidays', page: () => const ViewHolidayScreen()),
        GetPage(name: '/reset_password', page: () => const ResetPasswordScreen()),
      ],
    );
  }

}

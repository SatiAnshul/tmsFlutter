
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms/dto/common_api_dto.dart';
import 'package:tms/utils/pref_constant.dart';
import 'package:tms/view/holidays/holiday_screen.dart';

import '../../api/api_service.dart';
import '../../controller/dashboard_controller.dart';
import '../../dto/attendance_register_dto.dart';
import '../../dto/update_fcm_token_dto.dart';
import '../../response/attendance_marked_response.dart';
import '../../utils/attendance_bar_chart.dart';
import '../myattendance/mark_attendance/face_verification_screen.dart';
import '../myattendance/master_attendance/view_master_attendance_screen.dart';
import '../myattendance/view_attendance/view_attendance_screen.dart';
import '../reset_password/reset_password_screen.dart';



class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? empName;
  String? designation;
  String? userType;
  String? typeOfUser;
  final DashboardController dashboardController = Get.put(DashboardController());
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final api = ApiService();





  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _fetchDashboardSummary();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVersion(); // ensures UI is ready before showing dialog
    });  }


  Future<void> _fetchDashboardSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    final token = prefs.getString('auth_token') ?? '';

    final packageInfo = await PackageInfo.fromPlatform();
    final fullVersion = packageInfo.version; // "6.0.0"
    final majorVersion = fullVersion.split('.').first; // "6"
    final appName = packageInfo.packageName; // e.g. "com.tecxpert.tms"

    final dto = AttendanceRegisterDTO(
        userId: userId,
        fromDate: getFirstDateOfCurrentMonth(),
        toDate: getLocalDate(),
        APPVersion: majorVersion,
        APPName: appName
    );
    print("$userId , $getLocalDate() , $getFirstDateOfCurrentMonth() , $token");
    await dashboardController.fetchSummaryAttendance(dto, "Bearer $token");
    await getAndSendFcmToken(userId,token,appName,majorVersion);
  }
  Future<void> _checkVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final appName = packageInfo.packageName;
    final dto = CommonApiDto(
        strCode: appName,
        strType: PrefConstant.ANDROIDVERSION
    );
    print("Checking version for app: $appName , $dto");
    await dashboardController.checkVersionAPI(dto);
  }


  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      empName = prefs.getString('emp_name') ?? 'Employee';
      designation = prefs.getString('designation') ?? '';
      userType = prefs.getString('user_type') ?? '';
      typeOfUser = prefs.getString('type_of_user') ?? '';
    });
  }

  String getLocalDate() {
    final now = DateTime.now();
    return DateFormat('dd-MMM-yyyy', 'en').format(now);
  }
  String getFirstDateOfCurrentMonth() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    return DateFormat('dd-MMM-yyyy', 'en').format(firstDay);
  }



  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    final token = prefs.getString('auth_token') ?? '';
    final packageInfo = await PackageInfo.fromPlatform();
    final fullVersion = packageInfo.version; // "6.0.0"
    final majorVersion = fullVersion.split('.').first; // "6"
    final appName = packageInfo.packageName;
    await ResetFcmToken(userId,token,appName,majorVersion);
    await prefs.clear();
    Get.offAllNamed("/login");
    Get.snackbar("Logging Out", "You have been logged out",
        icon: const Icon(Icons.logout, color: Colors.black)
    );
  }
  Future<String?> _loadOrDownloadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    String? base64Image = prefs.getString('PREF_USER_IMAGE');

    // If we already have a cached image, return it
    if (base64Image != null && base64Image.isNotEmpty) {
      return base64Image;
    }

    // Otherwise, try downloading using stored file_info
    final fileInfo = prefs.getString('user_image_id');
    if (fileInfo != null && fileInfo.isNotEmpty) {
      base64Image = await downloadProfileImage(fileInfo);
      return base64Image;
    }

    // If no image found anywhere → null → fallback image
    return null;
  }

  Future<String?> downloadProfileImage(String fileInfo) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final userId = prefs.getString('user_id') ?? '';

    final url = Uri.parse("http://103.47.149.49:6550/api/TeamMgmt/FileDownload?userId=$userId&filename=$fileInfo");
    debugPrint("Downloading image with userId=$userId, fileInfo=$fileInfo");
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // Store as Base64
      final base64String = base64Encode(response.bodyBytes);
      await prefs.setString('PREF_USER_IMAGE', base64String);
      return base64String;
    } else {
      // Handle errors if needed
      debugPrint("Image download failed: ${response.body}");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Use a Container instead of DrawerHeader (default height : 200px) for flexible height
            Container(
              padding: const EdgeInsets.all(16),
              color: Color(0xFF0894DA),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(padding: const EdgeInsets.only(top: 40),child:Text(
                    "Welcome,\n${empName ?? ''}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),),
                  // const SizedBox(height: 16),
                  // const Divider( height: 16),
                  Padding(padding: const EdgeInsets.only(top: 40,bottom: 30), child:
                  Center(
                    child: FutureBuilder<String?>(
                      future: _loadOrDownloadProfileImage(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircleAvatar(
                            radius: 80,
                            backgroundColor: Colors.white,
                            child: CircularProgressIndicator(),
                          );
                        }

                        ImageProvider imageProvider;

                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          // ✅ Convert base64 → ImageProvider
                          final bytes = base64Decode(snapshot.data!);
                          imageProvider = MemoryImage(bytes);
                        } else {
                          // ✅ Fallback if no image found
                          imageProvider = const AssetImage('assets/images/no_img_icon.png');
                        }

                        return CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.white.withOpacity(0.8),
                          backgroundImage: imageProvider,
                        );
                      },
                    ),
                  )
                  )
                ],
              ),
            ),

            // 📜 Drawer menu items
            ListTile(
              leading: const Icon(Icons.lock, color: Colors.black),
              title: const Text("Reset Password", style: TextStyle(color: Colors.blueAccent)),
              onTap: () => Get.to(() => ResetPasswordScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.black),
              title: const Text("Logout", style: TextStyle(color: Colors.blueAccent)),
              onTap: _showLogoutConfirmationDialog,
            ),
          ],
        ),
      ),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "TMS Dashboard - ${designation ?? ''}",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFDAE9F4),
              Color(0xFFC0DCEA),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Summary Graph Section
              Obx(() {
                if (dashboardController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (dashboardController.summaryAttendanceList.isEmpty) {
                  return const Center(child: Text("No summary data available"));
                }

                final summary = dashboardController.summaryAttendanceList.first;

                return
                  Card(
                    elevation: 4,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Attendance Summary",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 220,
                            child: AttendanceBarChart(
                              workingDays: int.tryParse(summary.WorkingDays ?? "0") ?? 0,
                              presentDays: int.tryParse(summary.PresentDays ?? "0") ?? 0,
                              absentDays: int.tryParse(summary.AbsentDays ?? "0") ?? 0,
                              lateDays: int.tryParse(summary.LateDays ?? "0") ?? 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
              }),

              const SizedBox(height: 24),

              // Attendance and Other Services Cards Section
              _buildMainContent(),
            ],
          ),
        ),
      ),
    );
  }
  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // user must choose Yes or No
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Confirm Logout",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you sure you want to log out?",
            style: TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text("No"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog first
                _logout(); // Then perform logout
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }


  Widget _buildMainContent() {
    return Card(
      elevation: 3.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("My Attendance",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOptionCard("Mark Attendance", Icons.camera_alt, () {
                  Get.to(() => FaceVerificationScreen());
                }),
                if (userType == "Master" && typeOfUser == "Internal")
                  _buildOptionCard("Master Attendance", Icons.calendar_today, () {
                    Get.to(() => ViewMasterAttendanceScreen());
                  }),
                if (userType != "Master" && typeOfUser == "Internal")
                  _buildOptionCard("View Attendance", Icons.calendar_today, () {
                    Get.to(() => ViewAttendanceScreen());
                  }),
              ],
            ),
            const Text("Other Services",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOptionCard("Holidays", Icons.library_books, () {
                  Get.to(() => ViewHolidayScreen());
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Future<void> getAndSendFcmToken(String userId, String token,String appName , String appVersion) async {
    try {
      //Ask for notification permissions (important for iOS & Android 13+)
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      //Check SharedPreferences for stored FCM token
      final prefs = await SharedPreferences.getInstance();
      String? fcmToken = prefs.getString("fcm_token");

      //If no stored token, get a fresh one from Firebase
      fcmToken ??= await _messaging.getToken();

      if (fcmToken != null && fcmToken.isNotEmpty) {
        print(" FCM Token to send: $fcmToken");

        //Save/Update it in SharedPreferences for future use
        await prefs.setString("fcm_token", fcmToken);

        // Send it to your backend API
        final dto = UpdateFcmTokenDto(
          userId: userId,
          APPVersion: appVersion,
          APPName: appName,
          Token: fcmToken,
        );

        await dashboardController.updateFCMToken(userId, dto, "Bearer $token");
      } else {
        print(" Failed to get FCM token.");
      }
    } catch (e) {
      print("Error initializing FCM: $e");
    }
  }
  Future<void> ResetFcmToken(String userId, String token,String appName , String appVersion) async {
    try {
        final dto = UpdateFcmTokenDto(userId: userId, APPVersion: appVersion, APPName: appName, Token: "0");
        dashboardController.updateFCMToken(userId,dto,"Bearer $token");
    } catch (e) {
      print("Error getting FCM token: $e");
    }
  }

  Widget _buildOptionCard(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        color: Color(0xFF0894DA),
        elevation: 2.4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 120,
          height: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 10),
              Text(title, textAlign: TextAlign.center , style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

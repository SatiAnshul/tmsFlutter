
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms/view/holidays/holiday_screen.dart';

import '../../controller/dashboard_controller.dart';
import '../../dto/attendance_register_dto.dart';
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



  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _fetchDashboardSummary();
  }


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
    await prefs.clear();
    Get.offAllNamed("/login");
    Get.snackbar("Logging Out", "You have been logged out",
        icon: const Icon(Icons.logout, color: Colors.black)
    );
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
                    child: CircleAvatar(
                      radius: 80, // adjust size
                      backgroundColor: Colors.white.withOpacity(0.8),

                      // ✅ Fallback image now, later you can replace this with NetworkImage or FileImage
                      backgroundImage: const AssetImage('assets/images/no_img_icon.png'),
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
              onTap: _logout,
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

              // 📊 Summary Graph Section
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

              // 📦 Attendance and Other Services Cards Section
              _buildMainContent(),
            ],
          ),
        ),
      ),
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

  Widget _buildOptionCard(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        color: Color(0xFF0894DA),
        elevation: 2.4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

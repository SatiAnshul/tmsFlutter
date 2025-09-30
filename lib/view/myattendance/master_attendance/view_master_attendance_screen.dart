import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../controller/master_attendance_controller.dart';
import '../../../dto/attendance_register_dto.dart';
import '../../../utils/date_utils.dart';
import '../../../response/view_master_attendance_response.dart';

class ViewMasterAttendanceScreen extends StatefulWidget {
  const ViewMasterAttendanceScreen({super.key});

  @override
  State<ViewMasterAttendanceScreen> createState() =>
      _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewMasterAttendanceScreen> {
  final controller = Get.put(MasterAttendanceController());
  String? _selectedView = "Details";

  String? _fromDate;
  String? fullVersion;
  String? majorVersion;
  String? appName;
  String? _toDate;
  List<String> allDates = []; // 🔥 Master list of all dates (for columns)

  @override
  void initState()  {
    super.initState();
    _initData();
  }
  Future<void> _initData() async {
    _fromDate = _getLocalDateYesterday();
    _toDate = _getLocalDate();
    final packageInfo = await PackageInfo.fromPlatform();
    fullVersion = packageInfo.version; // "6.0.0"
    majorVersion = fullVersion?.split('.').first; // "6"
    appName = packageInfo.packageName; // e.g. "com.tecxpert.tms"
    if (_fromDate!.isNotEmpty && _toDate!.isNotEmpty) {
      if (_selectedView == "Details")
        _loadData();
      else if (_selectedView == "Summary")
        _loadSummaryData();
      // _loadData();
    }
  }


  String _getLocalDate() =>
      DateFormat('dd-MMM-yyyy', 'en').format(DateTime.now());

  String _getLocalDateYesterday() => DateFormat(
    'dd-MMM-yyyy',
    'en',
  ).format(DateTime.now().subtract(const Duration(days: 1)));

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = DateHelper.formatDate(picked);
        } else {
          _toDate = DateHelper.formatDate(picked);
        }
        if (_fromDate!.isNotEmpty && _toDate!.isNotEmpty) {
          if (_selectedView == "Details")
            _loadData();
          else if (_selectedView == "Summary")
            _loadSummaryData();
          // _loadData();
        }
      });
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id") ?? "";
    final token = prefs.getString("auth_token") ?? "";

    final dto = AttendanceRegisterDTO(
      userId: userId,
      fromDate: _fromDate!,
      toDate: _toDate!,
      APPVersion: majorVersion!,
      APPName: appName!,
    );

    await controller.fetchAttendance(dto, "Bearer $token");

    // ✅ Build master date list
    allDates.clear();
    for (var emp in controller.attendanceList) {
      for (var att in emp.attendanceList ?? []) {
        if (att?.date != null && !allDates.contains(att!.date!)) {
          allDates.add(att.date!);
        }
      }
    }
    // allDates.sort((a, b) =>
    //     DateFormat("dd-MM-yyyy").parse(a).compareTo(DateFormat("dd-MM-yyyy").parse(b)));
    setState(() {});
  }

  void _loadSummaryData() async {
    if (_fromDate != null && _toDate != null) {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id") ?? "";
      final token = prefs.getString("auth_token") ?? "";
      final dto = AttendanceRegisterDTO(
        userId: userId,
        // TODO: replace with SharedPrefs userId
        fromDate: _fromDate!,
        toDate: _toDate!,
        APPVersion: majorVersion!,
        APPName: appName!,
      );
      // TODO: load from SharedPrefs
      await controller.fetchSummaryAttendance(dto, "Bearer $token");
    } else {
      Get.snackbar("Error", "Please select both dates");
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Master Attendance"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF),
              Color(0xFFDAE9F4),
              Color(0xFFC0DCEA)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _BuildingMainTable(),
        ),
      ),
    );
  }

  Widget _BuildingMainTable() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // 📅 Date pickers row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickDate(isFrom: true),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _fromDate ?? "From Date",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickDate(isFrom: false),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _toDate ?? "To Date",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 🔄 Load data button
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedView = "Details";
                    });
                    _loadData();
                  },
                  child: const Text("Details",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedView = "Summary";
                    });
                    _loadSummaryData();
                  },
                  child: const Text("Summary",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 📊 Table Section
          if (_selectedView == "Summary")
            _buildSummaryAttendance()
          else if (_selectedView == "Details")
            _BuildMasterAttendance(),
        ],
      ),
    );
  }

  Widget _BuildMasterAttendance() {
    return Expanded(
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.attendanceList.isEmpty) {
          return const Center(child: Text("No data found"));
        }

        // ✅ Just one horizontal scroll with a vertical column inside
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Container(
                // color: Color(0xFFD6E9F3),
                decoration: BoxDecoration(
                color: const Color(0xFF0894DA), // background color
                borderRadius: BorderRadius.circular(12), // rounded corners
              ),
              child: _buildHeaderRow()),
                    const Divider(height: 2),
                    // ✅ Vertical list inside a column (no Expanded/SizedBox)
                    Column(
                      children: controller.attendanceList
                          .map((emp) => _buildEmployeeRow(emp))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSummaryAttendance() {
    return Expanded(
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.summaryAttendanceList.isEmpty) {
          return const Center(child: Text("No data found"));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Container(
        // color: Color(0xFFD6E9F3),
        decoration: BoxDecoration(
        color: const Color(0xFF0894DA), // background color
        border: Border.all(
        color: const Color(0xFF053B6B), // dark blue stroke
        width: 2, // thickness of the stroke
        ),
        borderRadius: BorderRadius.circular(12), // rounded corners
        ),
        child:
            Row(
              children: const [
                Expanded(
                  child: Text(
                    "Name",
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    "Working Days",
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    "Present",
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    "Absent",
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    "Late",
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )),
            const Divider(),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: controller.summaryAttendanceList.length,
                itemBuilder: (context, index) {
                  final item = controller.summaryAttendanceList[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                        // color: Color(0xFFD6E9F3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3), // background color
                          border: Border.all(
                            color: const Color(0xFF053B6B), // dark blue stroke
                            width: 2, // thickness of the stroke
                          ),
                          borderRadius: BorderRadius.circular(12), // rounded corners
                        ),
                        child:
                        Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.EmployeeName ?? "-",
                            style: const TextStyle(color: Colors.blueAccent),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.WorkingDays ?? "-",
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.PresentDays ?? "-",
                            style: const TextStyle(color: Colors.green),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.AbsentDays ?? "-",
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.LateDays ?? "-",
                            style: const TextStyle(color: Colors.orange),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  /// 🧱 Builds header row: Employee Name + all dates with In/Out
  Widget _buildHeaderRow() {
    return Row(
      children: [
        Container(
          width: 150,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.transparent, // background color
            borderRadius: BorderRadius.circular(12), // rounded corners
          ),
          child: const Text(
            "Employee Name",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(),
        ...allDates.map((date) {
          return Container(
            width: 140,
            padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.transparent, // background color
                border: Border.all(
                  color: const Color(0xFF053B6B), // dark blue stroke
                  width: 2, // thickness of the stroke
                ),
                borderRadius: BorderRadius.circular(12), // rounded corners
              ),
            child: Column(
              children: [
                Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("In", style: TextStyle(fontWeight: FontWeight.bold)),
                    const Divider(),
                    Text("Out", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildEmployeeRow(MasterAttendanceItem emp) {
    return Row(
      children: [
        // Employee name column
        Container(
          width: 150,
          padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.transparent, // background color
          border: Border.all(
            color: const Color(0xFF053B6B), // dark blue stroke
            width: 2, // thickness of the stroke
          ),
          borderRadius: BorderRadius.circular(12), // rounded corners
        ),
          child: Text(
            emp.employeeName ?? "-",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),

        // Attendance cells for each date
        ...allDates.map((date) {
          final entry = emp.attendanceList?.firstWhereOrNull(
            (e) => e?.date == date,
          );

          String inTime = entry?.inTime ?? "-";
          String outTime = entry?.outTime ?? "-";
          String reason = entry?.reason ?? "N/A";

          // Decide background and text colors
          Color bgColor = Colors.white;
          Color textColor = Colors.black;

          if (inTime == "Saturday" ||
              inTime == "Sunday" ||
              inTime == "Holiday") {
            bgColor = Colors.white;
            textColor = Colors.blue.shade900;
            inTime = inTime == "Holiday" ? "Holiday" : inTime.substring(0, 3);
            outTime = inTime;
          } else if (inTime == "AB") {
            bgColor = Colors.red.shade300;
            textColor = Colors.white;
            outTime = "AB";
          } else {
            // Parse time and check late condition
            try {
              final parsedTime = DateFormat("hh:mm a").parse(inTime);
              final thresholdTime = DateFormat("hh:mm a").parse("09:20 AM");

              if (parsedTime.isAfter(thresholdTime)) {
                bgColor = Colors.orange.shade300; // late
                textColor = Colors.blue.shade900;
              } else {
                bgColor = Colors.green.shade300; // on time
                textColor = Colors.blue.shade900;
              }
            } catch (_) {
              // ignore parse errors
            }
          }

          return GestureDetector(
            onDoubleTap: () {
              // 🟡 Optional: Show reason on double tap
              Get.snackbar("Reason", reason);
            },
            child: Container(
              width: 140,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border.all(
                  color: const Color(0xFF053B6B), // dark blue stroke
                  width: 2, // thickness of the stroke
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    inTime,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    outTime,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

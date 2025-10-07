import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../controller/attendance_controller.dart';
import '../../../dto/attendance_register_dto.dart';
import '../../../utils/date_utils.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row;
import 'package:share_plus/share_plus.dart';

class ViewAttendanceScreen extends StatefulWidget {
  const ViewAttendanceScreen({super.key});

  @override
  State<ViewAttendanceScreen> createState() => _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewAttendanceScreen> {
  final controller = Get.put(AttendanceController());

  String? _fromDate;
  String? _toDate;
  String? fullVersion;
  String? majorVersion;
  String? appName;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final packageInfo = await PackageInfo.fromPlatform();
    fullVersion = packageInfo.version;
    majorVersion = fullVersion?.split('.').first;
    appName = packageInfo.packageName;
    _fromDate = _getLocalDateYesterday();
    _toDate = _getLocalDate();
    if (_fromDate != null && _toDate != null) {
      _loadData();
    }
    _androidSdkInt();
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
        if (_fromDate != null && _toDate != null) {
          _loadData();
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
  }

  Future<bool> _ensureStoragePermission() async {
    // On Android 11+ (API 30+), MANAGE_EXTERNAL_STORAGE might be needed
    if (Platform.isAndroid && (await _androidSdkInt()) >= 30) {
      if (await Permission.manageExternalStorage.isGranted) return true;
      final result = await Permission.manageExternalStorage.request();
      if (result.isGranted) return true;

      Get.snackbar(
        "Permission Required",
        "Please enable 'All files access' from settings.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      await openAppSettings();
      return false;
    } else {
      // Below Android 11 — normal storage permission
      final status = await Permission.storage.request();
      if (status.isGranted) return true;

      Get.snackbar(
        "Permission Required",
        "Please allow storage permission to export attendance.",
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<int> _androidSdkInt() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.version.sdkInt;
  }

  Future<void> exportAttendanceExcel(
      List attendanceList,
      ) async
  {
    if (attendanceList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No attendance data available")),
      );
      return;
    }

    try {
      // Create workbook and sheet
      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];
      sheet.name = 'Attendance';

      // Define styles
      final Style headerStyle = workbook.styles.add('headerStyle');
      headerStyle.backColor = '#93D7EF'; // light blue
      headerStyle.bold = true;
      headerStyle.hAlign = HAlignType.center;
      headerStyle.vAlign = VAlignType.center;
      headerStyle.borders.all.lineStyle = LineStyle.thin;

      final Style cellStyle = workbook.styles.add('cellStyle');
      cellStyle.hAlign = HAlignType.center;
      cellStyle.vAlign = VAlignType.center;
      cellStyle.borders.all.lineStyle = LineStyle.thin;

      // Add title row (merged)
      final String title = "Attendance Report";
      sheet.getRangeByIndex(1, 1, 1, 3).merge();
      sheet.getRangeByIndex(1, 1).setText(title);
      sheet.getRangeByIndex(1, 1).cellStyle = headerStyle;
      sheet.getRangeByIndex(1, 1, 1, 3).rowHeight = 25;

      //Add header row
      final headers = ["Date", "In Time", "Out Time"];
      for (int i = 0; i < headers.length; i++) {
        sheet.getRangeByIndex(2, i + 1).setText(headers[i]);
        sheet.getRangeByIndex(2, i + 1).cellStyle = headerStyle;
      }

      // Add attendance data
      for (int i = 0; i < attendanceList.length; i++) {
        final item = attendanceList[i];
        sheet.getRangeByIndex(i + 3, 1).setText(item.date ?? "-");
        sheet.getRangeByIndex(i + 3, 2).setText(item.inTime ?? "-");
        sheet.getRangeByIndex(i + 3, 3).setText(item.outTime ?? "-");

        // Apply style to each data cell
        for (int c = 1; c <= 3; c++) {
          sheet.getRangeByIndex(i + 3, c).cellStyle = cellStyle;
        }
      }

      // Auto-fit all columns
      for (int c = 1; c <= 3; c++) {
        sheet.autoFitColumn(c);
      }

      //Save the file
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      final Directory directory = Platform.isAndroid
          ? (await getExternalStorageDirectory())!
          : await getApplicationDocumentsDirectory();

      final String fileName =
          "Attendance_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final String filePath = "${directory.path}/$fileName";
      final File outFile = File(filePath);
      await outFile.writeAsBytes(bytes);

      // Share the file
      await Share.shareXFiles([XFile(outFile.path)],
          text: "Attendance Excel Export");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Excel exported to $filePath")),
      );
    } catch (e) {
      debugPrint("Excel export error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to export Excel")),
      );
    }
  }

  Future<void> exportAttendancePdf(List attendanceList) async {
    final pdf = pw.Document();

    final data = attendanceList.map((item) => [
      item.date ?? "-",
      item.inTime ?? "-",
      item.outTime ?? "-"
    ]).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        header: (pw.Context context) => pw.Text(
          "Attendance Report",
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        build: (pw.Context context) {
          if (data.isEmpty) {
            return [pw.Center(child: pw.Text("No attendance data found"))];
          }
          return [
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: ["Date", "In Time", "Out Time"],
              data: data,
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.center,
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex("#D3D3D3")),
            ),
          ];
        },
      ),
    );

    // Save file (app folder + share)
    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    }

    final fileName = "attendance_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final filePath = "${directory!.path}/$fileName";
    final file = File(filePath);

    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: "Attendance Export");
  }



  // STEP 3: Master function to export with permission checks
  Future<void> _exportAttendanceinExcel() async {
    final granted = await _ensureStoragePermission();
    if (!granted) return;
    // await _generateExcelFile()
    await exportAttendanceExcel(controller.attendanceList);
  }
  Future<void> _exportAttendanceinPDF() async {
    final granted = await _ensureStoragePermission();
    if (!granted) return;
    // await _generateExcelFile()
    await exportAttendancePdf(controller.attendanceList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Attendance"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'excel') {
                await _exportAttendanceinExcel();
              } else if (value == 'pdf') {
                _exportAttendanceinPDF();
              }
            },
              itemBuilder: (context) => [
      const PopupMenuItem(
        value: 'pdf',
        child: Row(
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.red),
            SizedBox(width: 8),
            Text("Export to PDF"),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'excel',
        child: Row(
          children: [
            Icon(Icons.table_chart, color: Colors.green),
            SizedBox(width: 8),
            Text("Export to Excel"),
          ],
        ),
      ),
    ],
          ),
        ],
      ),
      body: Container(
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
        padding: const EdgeInsets.all(16),
        child: _buildMainTable(),
      ),
    );
  }

  Widget _buildMainTable() {
    return Column(
      children: [
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
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0894DA),
            border: BoxBorder.all(color: const Color(0xFF053B6B), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Expanded(child: Text("Date", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              Expanded(child: Text("In Time", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              Expanded(child: Text("Out Time", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.attendanceList.isEmpty) {
              return const Center(child: Text("No data found"));
            }
            return ListView.builder(
              itemCount: controller.attendanceList.length,
              itemBuilder: (context, index) {
                final item = controller.attendanceList[index];
                String inTime = item.inTime ?? "-";
                String outTime = item.outTime ?? "-";

                Color bgColor = Colors.transparent;
                Color textColor = Colors.black;

                if (inTime == "Saturday" || inTime == "Sunday" || inTime == "Holiday") {
                  bgColor = Colors.white;
                  textColor = Colors.blue.shade900;
                  inTime = inTime == "Holiday" ? "Holiday" : inTime.substring(0, 3);
                  outTime = inTime;
                } else if (inTime == "AB") {
                  bgColor = Colors.red.shade300;
                  textColor = Colors.white;
                  outTime = "AB";
                } else {
                  try {
                    final parsedTime = DateFormat("hh:mm a").parse(inTime);
                    final threshold = DateFormat("hh:mm a").parse("09:20 AM");
                    if (parsedTime.isAfter(threshold)) {
                      bgColor = Colors.orange.shade300;
                      textColor = Colors.white;
                    } else {
                      bgColor = Colors.green.shade300;
                      textColor = Colors.white;
                    }
                  } catch (_) {}
                }

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: BoxBorder.all(color: const Color(0xFF053B6B), width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(item.date ?? "-", style: TextStyle(color: textColor,fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      Expanded(child: Text(inTime, style: TextStyle(color: textColor,fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      Expanded(child: Text(outTime, style: TextStyle(color: textColor,fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}

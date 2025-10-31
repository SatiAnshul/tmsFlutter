import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../controller/master_attendance_controller.dart';
import '../../../dto/attendance_register_dto.dart';
import '../../../response/summary_attendance_response.dart';
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
  List<String> allDates = []; // Master list of all dates (for columns)

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

    // Build master date list
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

  Future<void> exportSummaryAttendanceExcel(
      List<summaryAttendanceItem> attendanceList,
      ) async {
    if (attendanceList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No data available to export")),
      );
      return;
    }

    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'Summary Attendance';

    // 📊 Define styles
    final Style headerStyle = workbook.styles.add('headerStyle');
    headerStyle.backColor = '#93D7EF'; // light blue header
    headerStyle.bold = true;
    headerStyle.hAlign = HAlignType.center;
    headerStyle.vAlign = VAlignType.center;

    final Style cellStyle = workbook.styles.add('cellStyle');
    cellStyle.hAlign = HAlignType.center;
    cellStyle.vAlign = VAlignType.center;

    // 📌 Title (merged)
    final String title = "Summary Attendance Report";
    sheet.getRangeByIndex(1, 1, 1, 5).merge();
    sheet.getRangeByIndex(1, 1).setText(title);
    sheet.getRangeByIndex(1, 1, 1, 5).cellStyle = headerStyle;
    sheet.getRangeByIndex(1, 1, 1, 5).rowHeight = 25;

    // 📋 Header row
    final headers = [
      "Employee Name",
      "Working Days",
      "Present Days",
      "Absent Days",
      "Late Days"
    ];
    for (int i = 0; i < headers.length; i++) {
      sheet.getRangeByIndex(2, i + 1).setText(headers[i]);
      sheet.getRangeByIndex(2, i + 1).cellStyle = headerStyle;
    }

    // 🧑‍💻 Fill data rows
    for (int i = 0; i < attendanceList.length; i++) {
      final item = attendanceList[i];
      sheet.getRangeByIndex(i + 3, 1).setText(item.EmployeeName ?? "-");
      sheet.getRangeByIndex(i + 3, 2).setNumber(
          double.tryParse(item.WorkingDays?.toString() ?? "0") ?? 0);
      sheet.getRangeByIndex(i + 3, 3).setNumber(
          double.tryParse(item.PresentDays?.toString() ?? "0") ?? 0);
      sheet.getRangeByIndex(i + 3, 4).setNumber(
          double.tryParse(item.AbsentDays?.toString() ?? "0") ?? 0);
      sheet.getRangeByIndex(i + 3, 5).setNumber(
          double.tryParse(item.LateDays?.toString() ?? "0") ?? 0);

      // apply cell style for all 5 columns
      for (int c = 1; c <= 5; c++) {
        sheet.getRangeByIndex(i + 3, c).cellStyle = cellStyle;
      }
    }

    // 📏 Auto-fit all columns
    for (int c = 1; c <= 5; c++) {
      sheet.autoFitColumn(c);
    }

    // 📁 Save Excel file
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final Directory directory = Platform.isAndroid
        ? (await getExternalStorageDirectory())!
        : await getApplicationDocumentsDirectory();

    final String fileName =
        "SummaryAttendance_${DateTime.now().millisecondsSinceEpoch}.xlsx";
    final String filePath = "${directory.path}/$fileName";
    final File outFile = File(filePath);
    await outFile.writeAsBytes(bytes);

    // 📤 Share file
    await Share.shareXFiles([XFile(outFile.path)],
        text: "Summary Attendance Export");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Excel exported to $filePath")),
    );
  }


  Future<void> exportSummaryAttendancePdf(List<summaryAttendanceItem> attendanceList) async {
    try {
      final pdf = pw.Document();

      //  Convert data for table
      final data = attendanceList.map((item) => [
        item.EmployeeName ?? "-",
        item.WorkingDays ?? "-",
        item.PresentDays ?? "-",
        item.AbsentDays ?? "-",
        item.LateDays ?? "-"
      ]).toList();

      //  Add PDF page
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(16),
          header: (pw.Context context) => pw.Center(
            child: pw.Text(
              "Attendance Summary Report",
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
          ),
          build: (pw.Context context) {
            if (data.isEmpty) {
              return [pw.Center(child: pw.Text("No attendance data found"))];
            }
            return [
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: [
                  "Employee Name",
                  "Working Days",
                  "Present Days",
                  "Absent Days",
                  "Late Days"
                ],
                data: data,
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFE0E0E0),
                ),
                cellAlignment: pw.Alignment.center,
                cellStyle: pw.TextStyle(fontSize: 11),
              ),
            ];
          },
        ),
      );

      // Save PDF file
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

      //Share the file
      await Share.shareXFiles([XFile(file.path)], text: "Attendance Export");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF exported to $filePath")),
      );
    } catch (e) {
      debugPrint("PDF Export error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to export PDF")),
      );
    }
  }

  Future<void> exportMasterAttendancePdf(
      List<MasterAttendanceItem> masterAttendanceList,
      List<String> masterAttDateList) async
  {
    final pdf = pw.Document();
    final dateFormat = DateFormat("hh:mm a");

    // Helper: ISO A-series sizes (points; 1 point = 1/72 inch)
    const double mm = 72.0 / 25.4;
    final pageA0 = PdfPageFormat(841 * mm, 1189 * mm);
    final pageA1 = PdfPageFormat(594 * mm, 841 * mm);
    final pageA2 = PdfPageFormat(420 * mm, 594 * mm);
    final pageA3 = PdfPageFormat(297 * mm, 420 * mm);
    final pageA4 = PdfPageFormat(210 * mm, 297 * mm);

    int dateColumnCount = masterAttDateList.length;
    int totalColumns = 1 + dateColumnCount * 2;

    PdfPageFormat chooseFormat(int totalCols) {
      if (totalCols > 60) return pageA0.landscape;
      if (totalCols > 40) return pageA1.landscape;
      if (totalCols > 25) return pageA2.landscape;
      if (totalCols > 10) return pageA3.landscape;
      return pageA4.landscape;
    }

    final pageFormat = chooseFormat(totalColumns);

    // Colors (match Kotlin dims)
    final lightBlue = PdfColor.fromInt(0xFF93D7EF);   // 147,215,239
    final lightRed = PdfColor.fromInt(0xFFFFCCCC);    // 255,204,204
    final lightGreen = PdfColor.fromInt(0xFFCCFFCC);  // 204,255,204
    final lightOrange = PdfColor.fromInt(0xFFFFE5CC); // 255,229,204
    final white = PdfColor.fromInt(0xFFFFFFFF);

    // Layout margins
    final double margin = 16.0;
    final double usableWidth = pageFormat.width - margin * 2;

    // Choose column widths like Kotlin: name col ~8% and rest shared by dates
    final double nameColWidth = usableWidth * 0.08;
    final double remaining = usableWidth - nameColWidth;
    final double singleDateBlockWidth = dateColumnCount > 0 ? remaining / dateColumnCount : remaining;
    final double inOutCellWidth = singleDateBlockWidth / 2.0;

    // Small text style
    final pw.TextStyle headerTextStyle = pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold);
    final pw.TextStyle cellTextStyle = pw.TextStyle(fontSize: 7);

    // Helper to produce a single data cell (in / out) with style logic
    pw.Widget styledCell(String inText, String outText, {bool isOut = false}) {
      final String display = isOut ? outText : inText;
      final String baseIn = inText;
      PdfColor bg = white;

      // transform weekend display
      String displayText = display;
      if (display == "Saturday") displayText = "Sat";
      if (display == "Sunday") displayText = "Sun";

      if (baseIn == "AB") {
        bg = lightRed;
      } else if (baseIn == "Holiday") {
        bg = white;
      } else if (baseIn == "Saturday" || baseIn == "Sunday") {
        bg = white;
      } else {
        try {
          final parsed = dateFormat.parse(baseIn);
          final threshold = dateFormat.parse("09:20 AM");
          if (parsed.isAfter(threshold)) {
            bg = lightOrange;
          } else {
            bg = lightGreen;
          }
        } catch (_) {
          bg = white;
        }
      }

      return pw.Container(
        width: inOutCellWidth,
        height: 20,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          color: bg,
          border: pw.Border.all(color: PdfColors.grey, width: 0.5),
        ),
        child: pw.Text(displayText, style: cellTextStyle),
      );
    }

    // Build header widget (title + date header + in/out subheader). Use header function
    pw.Widget buildHeader(pw.Context ctx) {
      final titleFontSize = (totalColumns > 60) ? 20.0 : (totalColumns > 40) ? 20.0 : (totalColumns > 25) ? 18.0 : (totalColumns > 10) ? 16.0 : 14.0;
      return pw.Column(children: [
        pw.SizedBox(height: 6),
        pw.Center(child: pw.Text("Master Attendance Report", style: pw.TextStyle(fontSize: titleFontSize, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 8),

        // Date header row: one date cell covering both In+Out
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Employee name header (rowspan visually)
            pw.Container(
              width: nameColWidth,
              height: 28,
              alignment: pw.Alignment.centerLeft,
              decoration: pw.BoxDecoration(color: lightBlue, border: pw.Border.all(color: PdfColors.grey)),
              padding: const pw.EdgeInsets.symmetric(horizontal: 4),
              child: pw.Text("Employee Name", style: headerTextStyle),
            ),

            // For each date, a single container width = inOutCellWidth*2
            for (var date in masterAttDateList)
              pw.Container(
                width: singleDateBlockWidth,
                height: 28,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(color: lightBlue, border: pw.Border.all(color: PdfColors.grey)),
                child: pw.Text(date, style: headerTextStyle),
              ),
          ],
        ),

        // In/Out sub-header row
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // blank under EmployeeName
            pw.Container(
              width: nameColWidth,
              height: 20,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(color: lightBlue, border: pw.Border.all(color: PdfColors.grey)),
              child: pw.Text("", style: headerTextStyle),
            ),
            // In / Out for each date
            for (var _ in masterAttDateList) ...[
              pw.Container(
                width: inOutCellWidth,
                height: 20,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(color: lightBlue, border: pw.Border.all(color: PdfColors.grey)),
                child: pw.Text("In", style: headerTextStyle),
              ),
              pw.Container(
                width: inOutCellWidth,
                height: 20,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(color: lightBlue, border: pw.Border.all(color: PdfColors.grey)),
                child: pw.Text("Out", style: headerTextStyle),
              ),
            ]
          ],
        ),
      ]);
    }

    // Build body rows (employee rows)
    List<pw.Widget> buildBodyRows() {
      final List<pw.Widget> rows = [];

      for (var item in masterAttendanceList) {
        final List<pw.Widget> children = [];

        // Employee name cell (left)
        children.add(pw.Container(
          width: nameColWidth,
          height: 20,
          alignment: pw.Alignment.centerLeft,
          padding: const pw.EdgeInsets.symmetric(horizontal: 4),
          decoration: pw.BoxDecoration(color: lightBlue, border: pw.Border.all(color: PdfColors.grey)),
          child: pw.Text(item.employeeName ?? "-", style: cellTextStyle),
        ));

        // For every date, add In & Out cells
        for (var date in masterAttDateList) {
          final record = item.attendanceList?.firstWhere((it) => it?.date == date);
          final inTime = record?.inTime ?? "AB";
          final outTime = record?.outTime ?? "AB";

          children.add(styledCell(inTime, outTime, isOut: false));
          children.add(styledCell(inTime, outTime, isOut: true));
        }

        rows.add(pw.Row(children: children));
      }

      return rows;
    }

    // Compose PDF page(s)
    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(margin),
        header: (ctx) => buildHeader(ctx),
        build: (ctx) {
          final bodyRows = buildBodyRows();
          // Place all rows inside a Column so MultiPage handles breaking across pages:
          return [
            pw.SizedBox(height: 6),
            pw.Column(children: bodyRows),
          ];
        },
      ),
    );

    try {
      final outputDir = (Platform.isAndroid) ? await getExternalStorageDirectory() : await getApplicationDocumentsDirectory();
      final fileName = "MasterAttendance_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File("${outputDir!.path}/$fileName");
      await file.writeAsBytes(await pdf.save());

      // Share the generated PDF
      await Share.shareXFiles([XFile(file.path)], text: "Master Attendance Export");

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF saved to ${file.path}")));
    } catch (e) {
      debugPrint("PDF export error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to export PDF: $e")));
    }
  }

  Future<void> exportMasterAttendanceExcel(
      List<MasterAttendanceItem> attendanceList,
      List<String> allDates,
      ) async
  {
    try {
      var excel = Excel.createExcel();
      final sheet = excel['Master Attendance'];

      // Title row
      final title = "Attendance List (${allDates.first} - ${allDates.last})";

      final totalColumns = 1 + allDates.length * 2;

      // Merge title row across all columns
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: totalColumns - 1, rowIndex: 0),
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
          .value = title;

      // Build header rows properly
      List<String> dateHeaderRow = ["Employee Name"];
      List<String> inOutHeaderRow = [""];

      for (var date in allDates) {
        dateHeaderRow.addAll([date]);
        inOutHeaderRow.addAll(["In", "Out"]);
      }

      // Append the two header rows
      sheet.appendRow(dateHeaderRow);
      sheet.appendRow(inOutHeaderRow);

      //Append attendance rows
      for (var emp in attendanceList) {
        List<String> row = [emp.employeeName ?? "-"];

        for (var date in allDates) {
          final entry = emp.attendanceList?.firstWhereOrNull((e) => e.date == date);
          String inTime = entry?.inTime ?? "AB";
          String outTime = entry?.outTime ?? "AB";
          row.addAll([inTime, outTime]);
        }

        sheet.appendRow(row);
      }

      //Save file
      Directory? directory = Platform.isAndroid
          ? await getExternalStorageDirectory()
          : await getApplicationDocumentsDirectory();

      final fileName =
          "MasterAttendance_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final file = File("${directory!.path}/$fileName");
      await file.writeAsBytes(excel.encode()!);

      await Share.shareXFiles([XFile(file.path)], text: "Master Attendance Export");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Excel saved to ${file.path}")),
      );
    } catch (e) {
      debugPrint("Excel export error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to export Excel")),
      );
    }
  }

  Future<void> exportMasterAttendanceExcelSyncfusion(
      List<MasterAttendanceItem> attendanceList,
      List<String> allDates,
      ) async
  {
    // safe-guard
    if (allDates.isEmpty || attendanceList.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("No data to export")));
      return;
    }

    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'Master Attendance';

    // 1-based indexing for Syncfusion XlsIO
    final DateFormat timeFormat = DateFormat("hh:mm a");

    final int totalColumns = 1 + allDates.length * 2; // 1 for name + 2 cols per date

    // --- Styles (use hex color strings) ---
    final Style titleStyle = workbook.styles.add('titleStyle');
    titleStyle.backColor = '#93D7EF'; // light blue
    titleStyle.hAlign = HAlignType.center;
    titleStyle.vAlign = VAlignType.center;
    titleStyle.bold = true;
    titleStyle.fontSize = 12;

    final Style headerWhite = workbook.styles.add('headerWhite');
    headerWhite.backColor = '#FFFFFF';
    headerWhite.hAlign = HAlignType.center;
    headerWhite.vAlign = VAlignType.center;
    headerWhite.bold = true;

    final Style styleBlue = workbook.styles.add('styleBlue'); // used for weekend header in kotlin
    styleBlue.backColor = '#93D7EF';
    styleBlue.hAlign = HAlignType.center;
    styleBlue.vAlign = VAlignType.center;
    styleBlue.bold = true;

    final Style styleRed = workbook.styles.add('styleRed');
    styleRed.backColor = '#FFCCCC';
    styleRed.hAlign = HAlignType.center;
    styleRed.vAlign = VAlignType.center;

    final Style styleGreen = workbook.styles.add('styleGreen');
    styleGreen.backColor = '#CCFFCC';
    styleGreen.hAlign = HAlignType.center;
    styleGreen.vAlign = VAlignType.center;

    final Style styleOrange = workbook.styles.add('styleOrange');
    styleOrange.backColor = '#FFE5CC';
    styleOrange.hAlign = HAlignType.center;
    styleOrange.vAlign = VAlignType.center;

    final Style styleDefault = workbook.styles.add('styleDefault');
    styleDefault.backColor = '#FFFFFF';
    styleDefault.hAlign = HAlignType.center;
    styleDefault.vAlign = VAlignType.center;

    // --- Title row (row 1) merged across all columns ---
    final String title =
        "Attendance List (${allDates.first} - ${allDates.last})";
    sheet.getRangeByIndex(1, 1, 1, totalColumns).merge();
    sheet.getRangeByIndex(1, 1).setText(title);
    sheet.getRangeByIndex(1, 1, 1, totalColumns).cellStyle = titleStyle;
    sheet.getRangeByIndex(1, 1, 1, totalColumns).rowHeight = 26;

    // --- Sub-header row (row 2): Employee Name + merged Dates label ---
    sheet.getRangeByIndex(2, 1).setText('Employee Name');
    sheet.getRangeByIndex(2, 1).cellStyle = styleBlue;
    if (totalColumns > 1) {
      sheet.getRangeByIndex(2, 2, 2, totalColumns).merge();
      sheet.getRangeByIndex(2, 2).setText('Dates');
      sheet.getRangeByIndex(2, 2, 2, totalColumns).cellStyle = styleBlue;
    }

    // --- Date row (row 3): each date merged over its In+Out columns ---
    int dateRowIndex = 3;
    int inOutRowIndex = 4;
    for (int i = 0; i < allDates.length; i++) {
      final int colStart = 2 + i * 2; // 1-based: col 2 is first date's In
      // merge date cell across two columns
      sheet.getRangeByIndex(dateRowIndex, colStart, dateRowIndex, colStart + 1)
        ..merge();
      sheet
          .getRangeByIndex(dateRowIndex, colStart)
          .setText(allDates[i]);
      sheet
          .getRangeByIndex(dateRowIndex, colStart, dateRowIndex, colStart + 1)
          .cellStyle = headerWhite;
    }

    // --- In/Out subheader row (row 4) ---
    for (int i = 0; i < allDates.length; i++) {
      final int colStart = 2 + i * 2;
      sheet.getRangeByIndex(inOutRowIndex, colStart).setText('In');
      sheet.getRangeByIndex(inOutRowIndex, colStart).cellStyle = headerWhite;
      sheet.getRangeByIndex(inOutRowIndex, colStart + 1).setText('Out');
      sheet.getRangeByIndex(inOutRowIndex, colStart + 1).cellStyle = headerWhite;
    }

    // --- Employee rows starting at row 5 ---
    int rowIndex = 5;
    final DateTime thresholdTime =
    timeFormat.parse("09:20 AM"); // used for late detection

    for (var emp in attendanceList) {
      // Employee name column
      sheet.getRangeByIndex(rowIndex, 1).setText(emp.employeeName ?? '-');
      // optional style for name column - keep white or light blue as you like
      sheet.getRangeByIndex(rowIndex, 1).cellStyle = styleDefault;

      // For each date, set In and Out with styling rules
      for (int i = 0; i < allDates.length; i++) {
        final int colStart = 2 + i * 2;
        // find record for this date (safe loop)
        dynamic record;
        if (emp.attendanceList != null) {
          for (var r in emp.attendanceList!) {
            if (r != null && r.date == allDates[i]) {
              record = r;
              break;
            }
          }
        }
        final String inTxt = (record?.inTime ?? "AB").toString();
        final String outTxt = (record?.outTime ?? "AB").toString();

        // Decide style (same logic as your Kotlin helpers)
        Style chosenStyle;
        if (inTxt == "AB") {
          chosenStyle = styleRed;
        } else if (inTxt == "Holiday") {
          chosenStyle = styleDefault; // Kotlin used red for Holiday in excel, but you can modify
        } else if (inTxt == "Saturday" || inTxt == "Sunday") {
          chosenStyle = styleBlue;
        } else {
          // parse time and compare
          try {
            final DateTime parsedIn = timeFormat.parse(inTxt);
            if (parsedIn.isAfter(thresholdTime)) {
              chosenStyle = styleOrange;
            } else {
              chosenStyle = styleGreen;
            }
          } catch (e) {
            chosenStyle = styleDefault;
          }
        }

        // write In cell
        sheet.getRangeByIndex(rowIndex, colStart).setText(inTxt);
        sheet.getRangeByIndex(rowIndex, colStart).cellStyle = chosenStyle;

        // write Out cell (we style out cell according to In text similar to Kotlin)
        sheet.getRangeByIndex(rowIndex, colStart + 1).setText(outTxt);
        sheet.getRangeByIndex(rowIndex, colStart + 1).cellStyle = chosenStyle;
      }

      rowIndex++;
    }

    // Optional: auto-fit columns (Syncfusion supports auto-fit)
    try {
      sheet.autoFitColumn(1); // name column
      for (int c = 2; c <= totalColumns; c++) {
        sheet.autoFitColumn(c);
        // or set fixed width: sheet.setColumnWidth(c, 20);
      }
    } catch (_) {
      // auto-fit may not be necessary; ignore failures
    }

    // Save file bytes
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    try {
      final Directory outputDir = Platform.isAndroid
          ? (await getExternalStorageDirectory() as Directory)
          : await getApplicationDocumentsDirectory();
      final String fileName =
          "MasterAttendance_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final File outFile = File('${outputDir.path}/$fileName');
      await outFile.writeAsBytes(bytes);

      // share
      await Share.shareXFiles([XFile(outFile.path)], text: "Master Attendance Export");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Excel saved to ${outFile.path}")),
      );
    } catch (e) {
      debugPrint('Failed to save/share Excel: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save Excel: $e")),
      );
    }
  }






  // STEP 3: Master function to export with permission checks
  Future<void> _exportSummaryAttendanceinExcel() async {
    final granted = await _ensureStoragePermission();
    if (!granted) return;
    // await _generateExcelFile()
    await exportSummaryAttendanceExcel(controller.summaryAttendanceList);
  }
  Future<void> _exportSummaryAttendanceinPDF() async {
    final granted = await _ensureStoragePermission();
    if (!granted) return;
    // await _generateExcelFile()
    await exportSummaryAttendancePdf(controller.summaryAttendanceList);
  }

  Future<void> _exportMasterAttendanceinExcel() async {
    final granted = await _ensureStoragePermission();
    if (!granted) return;
    // await _generateExcelFile()
    await exportMasterAttendanceExcelSyncfusion(controller.attendanceList,allDates);
  }
  Future<void> _exportMasterAttendanceinPDF() async {
    final granted = await _ensureStoragePermission();
    if (!granted) return;
    // await _generateExcelFile()
    await exportMasterAttendancePdf(controller.attendanceList,allDates);
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
        actions: [
          PopupMenuButton<String>(
            iconColor: Colors.white,
            onSelected: (value) async {
              if (value == 'excel') {
                if (_selectedView == "Details"){
                  await _exportMasterAttendanceinExcel();
                }else if (_selectedView == "Summary"){
                  await _exportSummaryAttendanceinExcel();
                }else{
                  Get.snackbar("Error", "Something went wrong");
                }

              } else if (value == 'pdf') {
                if (_selectedView == "Details"){
                  await _exportMasterAttendanceinPDF();
                }
                else if( _selectedView == "Summary"){
                  await _exportSummaryAttendanceinPDF();
                }else{
                  Get.snackbar("Error", "Something went wrong");
                }
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
            colors: [Color(0xFFFFFFFF),
              Color(0xFFDAE9F4),
              Color(0xFFC0DCEA)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: _BuildingMainTable(),
        ),
      ),
    );
  }

  Widget _BuildingMainTable() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Date pickers row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickDate(isFrom: true),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
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
                      padding: const EdgeInsets.all(8),
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

          // Load data button
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

          // Table Section
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
                  border: BoxBorder.all(
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
                        "Working",
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
                      border: BoxBorder.all(
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

  /// Builds header row: Employee Name + all dates with In/Out
  Widget _buildHeaderRow() {
    return Row(
      children: [
        Container(
          width: 130,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.transparent, // background color
            borderRadius: BorderRadius.circular(12), // rounded corners
          ),
          child: const Text(
            "Employee Name",
            style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white, fontSize: 14),
          ),
        ),
        const Divider(),
        ...allDates.map((date) {
          return Container(
            width: 120,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.transparent, // background color
              border: BoxBorder.all(
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
                    Text("In", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 12)),
                    const Divider(thickness: 2,height: 2,),
                    Text("Out", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 12)),
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
          width: 130,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.transparent, // background color
            border: BoxBorder.all(
              color: const Color(0xFF053B6B), // dark blue stroke
              width: 2, // thickness of the stroke
            ),
            borderRadius: BorderRadius.circular(12), // rounded corners
          ),
          child: Text(
            emp.employeeName ?? "-",
            style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 14),
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
              // Show reason on double tap
              Get.snackbar("Reason", reason);
            },
            child: Container(
              width: 120,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: bgColor,
                border: BoxBorder.all(
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
                      fontSize: 12
                    ),
                  ),
                  Text(
                    outTime,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12
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

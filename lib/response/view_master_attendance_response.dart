// lib/response/master_attendance_response.dart

class ViewMasterAttendanceResponse {
  final String? result;
  final List<MasterAttendanceItem>? getMasterAttendance;

  ViewMasterAttendanceResponse({this.result, this.getMasterAttendance});

  factory ViewMasterAttendanceResponse.fromJson(Map<String, dynamic> json) {
    return ViewMasterAttendanceResponse(
      result: json['Result'].toString(),
      getMasterAttendance: json['GetMasterAttendance'] != null
          ? List<MasterAttendanceItem>.from(
          (json['GetMasterAttendance'] as List)
              .map((e) => e != null
              ? MasterAttendanceItem.fromJson(e as Map<String, dynamic>)
              : null))
          : null,
    );
  }
}

class MasterAttendanceItem {
  final String? employeeName;
  final List<MasterAttendanceDateItem>? attendanceList;
  final String? result;

  MasterAttendanceItem({this.employeeName, this.attendanceList, this.result});

  factory MasterAttendanceItem.fromJson(Map<String, dynamic> json) {
    return MasterAttendanceItem(
      employeeName: json['EmployeeName'].toString(),
      attendanceList: json['AttendanceList'] != null
          ? List<MasterAttendanceDateItem>.from(
          (json['AttendanceList'] as List)
              .map((e) => e != null
              ? MasterAttendanceDateItem.fromJson(e as Map<String, dynamic>)
              : null))
          : null,
      result: json['Result'].toString(),
    );
  }
}

class MasterAttendanceDateItem {
  final String? date;
  final String? reason;
  final String? inTime;
  final String? outTime;

  MasterAttendanceDateItem({this.date, this.reason, this.inTime, this.outTime});

  factory MasterAttendanceDateItem.fromJson(Map<String, dynamic> json) {
    return MasterAttendanceDateItem(
      date: json['Date'].toString(),
      reason: json['Reason'].toString(),
      inTime: json['InTime'].toString(),
      outTime: json['OutTime'].toString(),
    );
  }
}

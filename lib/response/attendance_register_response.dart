class AttendanceRegisterResponse {
  final String? result;
  final List<AttendanceRegisterItem> items;

  AttendanceRegisterResponse({this.result, required this.items});

  factory AttendanceRegisterResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceRegisterResponse(
      result: json["Result"]?.toString(),
      items: (json["GetAttendanceRegister"] as List<dynamic>?)
          ?.map((e) => AttendanceRegisterItem.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class AttendanceRegisterItem {
  final String? date;
  final String? inTime;
  final String? outTime;

  AttendanceRegisterItem({this.date, this.inTime, this.outTime});

  factory AttendanceRegisterItem.fromJson(Map<String, dynamic> json) {
    return AttendanceRegisterItem(
      date: json["Date"].toString(),
      inTime: json["InTime"].toString(),
      outTime: json["OutTime"].toString(),
    );
  }
}

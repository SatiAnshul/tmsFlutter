class SummaryAttendanceResponse {
  final String? result;
  final List<summaryAttendanceItem> items;

  SummaryAttendanceResponse({this.result, required this.items});

  factory SummaryAttendanceResponse.fromJson(Map<String, dynamic> json) {
    return SummaryAttendanceResponse(
      result: json["Result"]?.toString(),
      items: (json["GetSummarizedAttendance"] as List<dynamic>?)
          ?.map((e) => summaryAttendanceItem.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class summaryAttendanceItem {
  final String? EmployeeName;
  final String? WorkingDays;
  final String? PresentDays;
  final String? AbsentDays;
  final String? LateDays;
  final String? Result;

  summaryAttendanceItem({this.EmployeeName, this.WorkingDays,this.PresentDays,this.AbsentDays ,this.LateDays,this.Result});

  factory summaryAttendanceItem.fromJson(Map<String, dynamic> json) {
    return summaryAttendanceItem(
      EmployeeName: json["EmployeeName"].toString(),
      WorkingDays: json["WorkingDays"].toString(),
      PresentDays: json["PresentDays"].toString(),
      AbsentDays: json["AbsentDays"].toString(),
      LateDays: json["LateDays"].toString(),
      Result: json["Result"].toString(),
    );
  }
}

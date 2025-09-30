class SummaryAttendanceDashboardResponse {
  final String? result;
  final List<summaryAttendanceDashoardItem> items;

  SummaryAttendanceDashboardResponse({this.result, required this.items});

  factory SummaryAttendanceDashboardResponse.fromJson(Map<String, dynamic> json) {
    return SummaryAttendanceDashboardResponse(
      result: json["Result"]?.toString(),
      items: (json["GetSummarizedAttendanceDashboard"] as List<dynamic>?)
          ?.map((e) => summaryAttendanceDashoardItem.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class summaryAttendanceDashoardItem {
  final String? EmployeeName;
  final String? WorkingDays;
  final String? PresentDays;
  final String? AbsentDays;
  final String? LateDays;
  final String? Result;

  summaryAttendanceDashoardItem({this.EmployeeName, this.WorkingDays,this.PresentDays,this.AbsentDays ,this.LateDays,this.Result});

  factory summaryAttendanceDashoardItem.fromJson(Map<String, dynamic> json) {
    return summaryAttendanceDashoardItem(
      EmployeeName: json["EmployeeName"].toString(),
      WorkingDays: json["WorkingDays"].toString(),
      PresentDays: json["PresentDays"].toString(),
      AbsentDays: json["AbsentDays"].toString(),
      LateDays: json["LateDays"].toString(),
      Result: json["Result"].toString(),
    );
  }
}

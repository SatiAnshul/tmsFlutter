class AttendanceMarkedResponse {
  final List<DataItem> items;

  AttendanceMarkedResponse({required this.items});

  factory AttendanceMarkedResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceMarkedResponse(
      // result: json["result"]?.toString(),
      items: (json["Loving"] as List<dynamic>?)
          ?.map((e) => DataItem.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class DataItem {
  final String? Result;
  final String? Response_Code;
  final String? Response;

  DataItem({this.Result, this.Response_Code, this.Response});

  factory DataItem.fromJson(Map<String, dynamic> json) {
    return DataItem(
      Result: json["Result"].toString(),
      Response_Code: json["Response_Code"].toString(),
      Response: json["Response"].toString(),
    );
  }
}

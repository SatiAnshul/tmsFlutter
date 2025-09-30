class HolidaysResponse {
  final List<HolidayItem> items;

  HolidaysResponse({required this.items});

  factory HolidaysResponse.fromJson(Map<String, dynamic> json) {
    return HolidaysResponse(
      items: (json["GetHolidaysList"] as List<dynamic>?)
          ?.map((e) => HolidayItem.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class HolidayItem {
  final String? SNo;
  final String? Occasion;
  final String? Day;
  final String? HolidayDate;
  final String? Result;

  HolidayItem({this.SNo, this.Occasion, this.Day, this.HolidayDate, this.Result});

  factory HolidayItem.fromJson(Map<String, dynamic> json) {
    return HolidayItem(
      SNo: json["SNo"].toString(),
      Occasion: json["Occasion"].toString(),
      Day: json["Day"].toString(),
      HolidayDate: json["HolidayDate"].toString(),
      Result: json["Result"].toString(),
    );
  }
}

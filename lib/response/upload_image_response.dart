class UploadImageResponse {
  final String? result;
  final List<DataItem> items;

  UploadImageResponse({this.result, required this.items});

  factory UploadImageResponse.fromJson(Map<String, dynamic> json) {
    return UploadImageResponse(
      result: json["result"]?.toString(),
      items: (json["data"] as List<dynamic>?)
          ?.map((e) => DataItem.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class DataItem {
  final String? Result;
  final String? Response_Code;
  final String? File_Info;

  DataItem({this.Result, this.Response_Code, this.File_Info});

  factory DataItem.fromJson(Map<String, dynamic> json) {
    return DataItem(
      Result: json["Result"].toString(),
      Response_Code: json["Response_Code"].toString(),
      File_Info: json["File_Info"].toString(),
    );
  }
}

class CommonApiResponse {
  final String? result;
  final List<CommonApiItem> items;
  final String? errorMessage;

  CommonApiResponse({this.result, required this.items , this.errorMessage});

  factory CommonApiResponse.fromJson(Map<String, dynamic> json) {
    return CommonApiResponse(
      result: json["Result"]?.toString(),
      items: (json["GetFixedParameter"] as List<dynamic>?)
          ?.map((e) => CommonApiItem.fromJson(e))
          .toList() ??
          [],
      errorMessage: json["Error_Msg"]?.toString()
    );
  }
}

class CommonApiItem {
  final String? Description;
  final String? Specification;


  CommonApiItem({this.Description, this.Specification});

  factory CommonApiItem.fromJson(Map<String, dynamic> json) {
    return CommonApiItem(
      Description: json["Description"].toString(),
      Specification: json["Specification"].toString(),

    );
  }
}

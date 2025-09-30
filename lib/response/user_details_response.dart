class UserDetailsResponse {
  final List<UserDetailItem> items;

  UserDetailsResponse({required this.items});

  factory UserDetailsResponse.fromJson(Map<String, dynamic> json) {
    return UserDetailsResponse(
      items: (json["GetUserDetails"] as List<dynamic>?)
          ?.map((e) => UserDetailItem.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class UserDetailItem {
  final String? UserName;
  final String? UserDesignation;
  final String? ImageId;
  final String? UserType;
  final String? VerifyType;
  final String? ClientCode;
  final String? Type;
  final String? Result;

  UserDetailItem({this.UserName, this.UserDesignation, this.ImageId, this.UserType,
    this.VerifyType, this.ClientCode, this.Type,this.Result});

  factory UserDetailItem.fromJson(Map<String, dynamic> json) {
    return UserDetailItem(
      UserName: json["UserName"].toString(),
      UserDesignation: json["UserDesignation"].toString(),
      ImageId: json["ImageId"].toString(),
      UserType: json["UserType"].toString(),
      VerifyType: json["VerifyType"].toString(),
      ClientCode: json["ClientCode"].toString(),
      Type: json["Type"].toString(),
      Result: json["Result"].toString(),
    );
  }
}

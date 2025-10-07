class UpdateFcmTokenDto {
  final String userId;
  final String APPVersion;
  final String APPName;
  final String Token;

  UpdateFcmTokenDto({
    required this.userId,
    required this.APPVersion,
    required this.APPName,
    required this.Token,
  });

  Map<String, String> toJson() => {
    "userId": userId,
    "APPVersion": APPVersion,
    "APPName": APPName,
    "Token": Token,
  };
}

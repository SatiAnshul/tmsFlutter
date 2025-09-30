class HolidaysDTO {
  final String userId;
  final String APPVersion;
  final String APPName;

  HolidaysDTO({
    required this.userId,
    required this.APPVersion,
    required this.APPName,
  });

  Map<String, String> toQuery() => {
    "userId": userId,
    "APPVersion": APPVersion,
    "APPName": APPName,
  };
}

class UserDetailsDTO {
  final String userId;
  final String APPVersion;
  final String APPName;

  UserDetailsDTO({
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

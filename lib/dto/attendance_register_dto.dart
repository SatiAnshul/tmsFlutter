class AttendanceRegisterDTO {
  final String userId;
  final String fromDate;
  final String toDate;
  final String APPVersion;
  final String APPName;

  AttendanceRegisterDTO({
    required this.userId,
    required this.fromDate,
    required this.toDate,
    required this.APPVersion,
    required this.APPName,
  });

  // Map<String, String> toQuery() {
  //   return {
  //     "userId": userId,
  //     "fromDate": fromDate,
  //     "toDate": toDate,
  //     "APPVersion": APPVersion,
  //     "APPName": APPName,
  //   };
  // }
  Map<String, String> toQuery() => {
    "userId": userId,
    "fromDate": fromDate,
    "toDate": toDate,
    "APPVersion": APPVersion,
    "APPName": APPName,
  };
}

// lib/dto/login_request.dart
class AttendanceMarkDto {
  final String UserId;
  final String AppUserCode;
  final String Latitude;
  final String Longitude;
  final String FILE_INFO;
  final String Reason;
  final String APPVersion;
  final String APPName;

  AttendanceMarkDto({
    required this.UserId,
    required this.AppUserCode,
    required this.Latitude,
    required this.Longitude,
    required this.FILE_INFO,
    required this.Reason,
    required this.APPVersion,
    required this.APPName,
  });

  Map<String, dynamic> toJson() =>
      {
        "UserId": UserId,
        "AppUserCode": AppUserCode,
        "Latitude": Latitude,
        "Longitude": Longitude,
        "FILE_INFO": FILE_INFO,
        "Reason": Reason,
        "APPVersion": APPVersion,
        "APPName": APPName,
      };

}

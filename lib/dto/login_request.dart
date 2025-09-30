// lib/dto/login_request.dart
class LoginRequest {
  final String userCode;
  final String password;
  final String appVersion;
  final String appName;

  LoginRequest({
    required this.userCode,
    required this.password,
    required this.appVersion,
    required this.appName,
  });

  Map<String, dynamic> toJson() => {
    "userCode": userCode,
    "password": password,
    "APPVersion": appVersion,
    "APPName": appName,
  };
}

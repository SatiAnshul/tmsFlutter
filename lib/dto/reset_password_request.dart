// lib/dto/login_request.dart
class ResetPasswordRequest {
  final String UserCode;
  final String OldPwd;
  final String NewPwd;

  ResetPasswordRequest({
    required this.UserCode,
    required this.OldPwd,
    required this.NewPwd,
  });

  Map<String, dynamic> toJson() => {
    "UserCode": UserCode,
    "OldPwd": OldPwd,
    "NewPwd": NewPwd,
  };
}

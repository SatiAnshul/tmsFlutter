// lib/response/login_response.dart
class ResetPasswordResponse {
  final String? result;
  final String? errorMessage;

  ResetPasswordResponse({this.result, this.errorMessage});

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResponse(
      result: json['result'].toString(),
      errorMessage: json['message'] ?? json['Message'] ?? json['error'] ?? json['Error'] ?? json['Result']?.toString(),
    );
  }
}

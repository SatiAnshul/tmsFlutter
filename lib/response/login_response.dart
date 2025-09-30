// lib/response/login_response.dart
class LoginResponse {
  final String? token;
  final String? errorMessage;

  LoginResponse({this.token, this.errorMessage});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'].toString(),
      errorMessage: json['errorMessage'].toString(),
    );
  }
}

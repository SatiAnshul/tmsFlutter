// lib/controller/login_controller.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import '../dto/login_request.dart';
import '../dto/update_fcm_token_dto.dart';
import '../dto/user_details_dto.dart';
import '../response/login_response.dart';
import '../response/user_details_response.dart';

class LoginController extends GetxController {
  var isLoading = false.obs;
  final api = ApiService();
  var loginResponse = Rxn<LoginResponse>();


  Future<void> login(String userCode, String password) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final fullVersion = packageInfo.version; // "6.0.0"
    final majorVersion = fullVersion.split('.').first; // "6"
    final appName = packageInfo.packageName; // e.g. "com.tecxpert.tms"

    if (userCode.isEmpty || password.isEmpty) {
      Get.snackbar("Error", "Please enter user code and password");
      return;
    }

    try {
      isLoading.value = true;


      final request = LoginRequest(
        userCode: userCode,
        password: password,
        appVersion: majorVersion,
        appName: appName,
      );

      final LoginResponse response = await api.login(request);

      if (response.token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("auth_token", response.token!);
        await prefs.setString("user_id", request.userCode);
        await prefs.setBool("is_logged", true);

        loginResponse.value = response;

        await _fetchAndSaveUserDetails(request.userCode, response.token!,appName,majorVersion);

        Get.snackbar("Success", "Login successful");
        Get.offAllNamed("/dashboard");
      } else {
        Get.snackbar("Login Failed", response.errorMessage ?? "Unknown error");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }


  Future<void> _fetchAndSaveUserDetails(String userId, String token,String appName , String appVersion) async {
    try {
      final dto = UserDetailsDTO(
        userId: userId,
        APPVersion: appVersion,
        APPName: appName,
      );

      final UserDetailsResponse details =
      await api.getUserDetails(dto, "Bearer $token");

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString("emp_name", details.items[0].UserName ?? "");
      await prefs.setString("designation", details.items[0].UserDesignation ?? "");
      await prefs.setString("user_type", details.items[0].UserType ?? "");
      await prefs.setString("type_of_user", details.items[0].Type ?? "");
      await prefs.setString("user_image_id", details.items[0].ImageId ?? "");

      await _updateFcmTokenOnServer(userId, appName,appVersion,"Bearer $token");

    } catch (e) {
      // Don’t block login if this fails
      print("User details fetch failed: $e");
    }
  }
  Future<void> _updateFcmTokenOnServer(String userId, String AppName,String AppVersion,String bearerJwtToken) async {
    try {

      String? fcmDeviceToken = await FirebaseMessaging.instance.getToken();

      if (fcmDeviceToken != null && fcmDeviceToken.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("fcm_token", fcmDeviceToken);
        // Create the DTO with the Device Token
        final fcmDto = UpdateFcmTokenDto(userId: userId,APPName:AppName ,APPVersion: AppVersion,Token: fcmDeviceToken);

        // Call ApiService using the Bearer JWT for Auth
        await api.updateFCMToken(
          userId: userId,
          dto: fcmDto,
          token: bearerJwtToken,
        );
        print("🚀 FCM Token Sync: Success using JWT Auth");
      }
    } catch (e) {
      print("❌ FCM Sync Error: $e");
    }
  }




}

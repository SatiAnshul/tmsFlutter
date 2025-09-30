import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_service.dart';
import '../dto/reset_password_request.dart';
import '../response/reset_password_response.dart';

class ResetPasswordController extends GetxController {
  var isLoading = false.obs;
  final api = ApiService();
  var resetResponse = Rxn<ResetPasswordResponse>();

  Future<void> resetPassword(String oldPwd, String newPwd) async {
    if (oldPwd.isEmpty || newPwd.isEmpty) {
      Get.snackbar("Error", "Please enter both password");
      return;
    }

    try {
      isLoading.value = true;

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id") ?? "";

      print("📡 Reset request: userId=$userId | old=$oldPwd | new=$newPwd");

      final request = ResetPasswordRequest(
        UserCode: userId,
        OldPwd: oldPwd,
        NewPwd: newPwd,
      );

      final response = await api.resetPassword(request);

      if (response.result == 'true') {
        resetResponse.value = response;
        print("✅ Reset response: ${response.result}");
        Get.offAllNamed("/dashboard");
        Get.snackbar(
          "Password Changed",
          "Successful",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        // Future.delayed(const Duration(milliseconds: 300), () {
        //   Get.back();
        // });
      } else {
        Get.snackbar(
          "Password Change Failed",
          response.errorMessage ?? "Unknown error",
          snackPosition: SnackPosition.BOTTOM,
        );
      }

    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}

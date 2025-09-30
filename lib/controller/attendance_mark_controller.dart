import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms/response/attendance_marked_response.dart';

import '../api/api_service.dart';
import '../dto/attendance_mark_dto.dart';

class AttendanceMarkController extends GetxController {
  var isLoading = false.obs;
  final api = ApiService();
  var callAttendanceResponse = Rxn<AttendanceMarkedResponse>();

  Future<void> attendanceMarking(String latitude, String longitude , String File_Info , String Reason) async {
    // if (userCode.isEmpty || password.isEmpty) {
    //   Get.snackbar("Error", "Please enter user code and password");
    //   return;
    // }

    try {
      isLoading.value = true;
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";
      final userId = prefs.getString("user_id") ?? "";

      final packageInfo = await PackageInfo.fromPlatform();
      final fullVersion = packageInfo.version; // "6.0.0"
      final majorVersion = fullVersion.split('.').first; // "6"
      final appName = packageInfo.packageName; // e.g. "com.tecxpert.tms"



      final request = AttendanceMarkDto(
        UserId: userId,
        AppUserCode: userId,
        Latitude: latitude,
        Longitude: longitude,
        FILE_INFO: File_Info,
        Reason: Reason,
        APPVersion: majorVersion,
        APPName: appName,
      );

      final AttendanceMarkedResponse response = await api.callAttendance(
          userId: userId, dto: request, token: "Bearer $token");

      if (response.items[0].Result.toString() == "true") {


        callAttendanceResponse.value = response;

        // await _fetchAndSaveUserDetails(request.userCode, response.token!);

        Get.snackbar("Success", "Attendance Marked successful");
        Get.back();
      } else {
        Get.snackbar("Attendance Failed",
            response.items[0].Response.toString() ?? "Unknown error");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

}
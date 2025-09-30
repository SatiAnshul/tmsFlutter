import 'package:get/get.dart';
import '../api/api_service.dart';
import '../dto/attendance_register_dto.dart';
import '../response/attendance_register_response.dart';

// class MasterAttendanceController extends GetxController {
//   var isLoading = false.obs;
//   var attendanceList = <AttendanceRegisterItem>[].obs;
//
//   final api = ApiService();
//
//   Future<void> fetchAttendance(AttendanceRegisterDTO dto, String token) async {
//     try {
//       isLoading.value = true;
//       final response = await api.getAttendanceRegister(dto, token);
//       attendanceList.assignAll(response.items);
//     } catch (e) {
//       Get.snackbar("Error", e.toString());
//     } finally {
//       isLoading.value = false;
//     }
//   }
// }
import '../response/summary_attendance_response.dart';
import '../response/view_master_attendance_response.dart';

class MasterAttendanceController extends GetxController {
  var isLoading = false.obs;
  var attendanceList = <MasterAttendanceItem>[].obs;
  var summaryAttendanceList = <summaryAttendanceItem>[].obs;
  final api = ApiService();

  /// Fetch attendance from backend
  Future<void> fetchAttendance(AttendanceRegisterDTO dto, String token) async {
    try {
      isLoading.value = true;

      // Call API (make sure your api service returns MasterAttendanceResponse)
      final response = await api.getMasterAttendanceRegister(dto, token);

      if (response != null && response.getMasterAttendance != null) {
        // Clear existing list
        attendanceList.clear();
        // Add new items
        attendanceList.addAll(response.getMasterAttendance!.whereType<MasterAttendanceItem>());
      } else {
        attendanceList.clear();
        Get.snackbar("No Data", "No attendance records found");
      }
    } catch (e) {
      attendanceList.clear();
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSummaryAttendance(AttendanceRegisterDTO dto, String token) async {
    try {
      isLoading.value = true;

      // Call API (make sure your api service returns MasterAttendanceResponse)
      final response = await api.getSummaryAttendance(dto, token);

      if (response != null && response.items != null) {
        // Clear existing list
        summaryAttendanceList.clear();
        // Add new items
        summaryAttendanceList.addAll(response.items!.whereType<summaryAttendanceItem>());
      } else {
        summaryAttendanceList.clear();
        Get.snackbar("No Data", "No attendance records found");
      }
    } catch (e) {
      summaryAttendanceList.clear();
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }


}


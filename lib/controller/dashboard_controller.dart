import 'package:get/get.dart';
import 'package:tms/response/summary_attendance_dashboard_response.dart';
import '../api/api_service.dart';
import '../dto/attendance_register_dto.dart';


class DashboardController extends GetxController {
  var isLoading = false.obs;
  var summaryAttendanceList = <summaryAttendanceDashoardItem>[].obs;
  final api = ApiService();

  Future<void> fetchSummaryAttendance(AttendanceRegisterDTO dto, String token) async {
    try {
      isLoading.value = true;

      // Call API (make sure your api service returns MasterAttendanceResponse)
      final response = await api.getSummaryAttendanceDashboard(dto, token);

      if (response != null && response.items != null) {
        // Clear existing list
        summaryAttendanceList.clear();
        // Add new items
        summaryAttendanceList.addAll(response.items!.whereType<summaryAttendanceDashoardItem>());
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


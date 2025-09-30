import 'package:get/get.dart';
import '../api/api_service.dart';
import '../dto/attendance_register_dto.dart';
import '../response/attendance_register_response.dart';

class AttendanceController extends GetxController {
  var isLoading = false.obs;
  var attendanceList = <AttendanceRegisterItem>[].obs;

  final api = ApiService();

  Future<void> fetchAttendance(AttendanceRegisterDTO dto, String token) async {
    try {
      isLoading.value = true;
      final response = await api.getAttendanceRegister(dto, token);
      attendanceList.assignAll(response.items);
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}

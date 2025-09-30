import 'package:get/get.dart';
import 'package:tms/dto/holidays_dto.dart';
import 'package:tms/response/holidays_response.dart';
import '../api/api_service.dart';

class HolidaysController extends GetxController {
  var isLoading = false.obs;
  var holidayList = <HolidayItem>[].obs;

  final api = ApiService();

  Future<void> fetchHoliday(HolidaysDTO dto, String token) async {
    try {
      isLoading.value = true;
      final response = await api.getHolidayList(dto, token);
      holidayList.assignAll(response.items);
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}

// lib/api/api_service.dart
import 'package:tms/dto/common_api_dto.dart';
import 'package:tms/dto/holidays_dto.dart';
import 'package:tms/dto/reset_password_request.dart';
import 'package:tms/dto/update_fcm_token_dto.dart';
import 'package:tms/response/common_api_response.dart';
import 'package:tms/response/holidays_response.dart';
import 'package:tms/response/reset_password_response.dart';
import 'package:tms/response/user_details_response.dart';
import 'package:tms/utils/pref_constant.dart';
import '../dto/attendance_mark_dto.dart';
import '../dto/attendance_register_dto.dart';
import '../dto/login_request.dart';
import '../dto/user_details_dto.dart';
import '../response/attendance_marked_response.dart';
import '../response/attendance_register_response.dart';
import '../response/login_response.dart';
import '../response/summary_attendance_dashboard_response.dart';
import '../response/summary_attendance_response.dart';
import '../response/view_master_attendance_response.dart';
import 'api_client.dart';

class ApiService {
  final ApiClient apiClient = ApiClient();

  Future<LoginResponse> login(LoginRequest request) async {
    final response =
    await apiClient.post(PrefConstant.LOGIN, body: request.toJson());
    return LoginResponse.fromJson(response);
  }


  Future<ResetPasswordResponse> resetPassword(ResetPasswordRequest request) async {
    final response =
    await apiClient.post(PrefConstant.RESETPASSWORD, body: request.toJson());
    return ResetPasswordResponse.fromJson(response);
  }

  Future<AttendanceRegisterResponse> getAttendanceRegister(
      AttendanceRegisterDTO dto, String token) async {
    final response = await apiClient.get(
      PrefConstant.ATTENDANCE_REGISTER,
      queryParameters: dto.toQuery(),
      headers: {"Authorization": token},
    );

    return AttendanceRegisterResponse.fromJson(response);
  }

  Future<HolidaysResponse> getHolidayList(HolidaysDTO dto, String token) async {
    final response = await apiClient.get(
      PrefConstant.GET_HOLIDAYS,
      queryParameters: dto.toQuery(),
      headers: {"Authorization": token},
    );

    return HolidaysResponse.fromJson(response);
  }

  Future<UserDetailsResponse> getUserDetails(UserDetailsDTO dto,
      String token) async {
    final response = await apiClient.get(
      PrefConstant.GET_USER_TYPE,
      queryParameters: dto.toQuery(),
      headers: {"Authorization": token},
    );
    return UserDetailsResponse.fromJson(response);
  }

  Future<AttendanceMarkedResponse> callAttendance({
    required String userId,
    required AttendanceMarkDto dto,
    required String token,
  }) async {
    final response = await apiClient.postWithQuery(
      PrefConstant.ATTENDANCE,
      queryParameters: {"UserId": userId},
      body: dto.toJson(),
      headers: {"Authorization": token},
    );
    return AttendanceMarkedResponse.fromJson(response);
  }

  Future<ViewMasterAttendanceResponse> getMasterAttendanceRegister(
      AttendanceRegisterDTO dto, String token) async {
    final response = await apiClient.get(
      PrefConstant.MASTER_ATTENDANCE_REGISTER,
      queryParameters: dto.toQuery(),
      headers: {"Authorization": token},
    );

    return ViewMasterAttendanceResponse.fromJson(response);
  }

  Future<SummaryAttendanceResponse> getSummaryAttendance(
      AttendanceRegisterDTO dto, String token) async {
    final response = await apiClient.get(
      PrefConstant.GET_MASTER_ATTENDANCE_SUMMARY,
      queryParameters: dto.toQuery(),
      headers: {"Authorization": token},
    );
    return SummaryAttendanceResponse.fromJson(response);
  }

  Future<SummaryAttendanceDashboardResponse> getSummaryAttendanceDashboard(
      AttendanceRegisterDTO dto, String token) async {
    final response = await apiClient.get(
      PrefConstant.GET_SUMMARIZED_ATTENDANCE_DASHBOARD,
      queryParameters: dto.toQuery(),
      headers: {"Authorization": token},
    );
    return SummaryAttendanceDashboardResponse.fromJson(response);
  }
  Future<CommonApiResponse> getFixedParameter(
      CommonApiDto dto) async {
    final response = await apiClient.getWithoutToken(
      PrefConstant.GET_FIXED_PARAMETER,
      queryParameters: dto.toQuery()
    );
    return CommonApiResponse.fromJson(response);
  }

  Future<AttendanceMarkedResponse> updateFCMToken({
    required String userId,
    required UpdateFcmTokenDto dto,
    required String token,
  }) async {
    final response = await apiClient.postWithQuery(
      PrefConstant.UPDATE_FCM_TOKEN,
      queryParameters: {"userId": userId},
      body: dto.toJson(),
      headers: {"Authorization": token},
    );
    return AttendanceMarkedResponse.fromJson(response);
  }





}

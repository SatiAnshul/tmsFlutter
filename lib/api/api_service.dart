// lib/api/api_service.dart
import 'dart:convert';

import 'package:tms/dto/holidays_dto.dart';
import 'package:tms/dto/reset_password_request.dart';
import 'package:tms/response/holidays_response.dart';
import 'package:tms/response/reset_password_response.dart';
import 'package:tms/response/user_details_response.dart';

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
    await apiClient.post("TeamMgmt/UsersLogin", body: request.toJson());
    return LoginResponse.fromJson(response);
  }


  Future<ResetPasswordResponse> resetPassword(ResetPasswordRequest request) async {
    final response =
    await apiClient.post("TeamMgmt/ResetPwd", body: request.toJson());
    return ResetPasswordResponse.fromJson(response);
  }

  Future<AttendanceRegisterResponse> getAttendanceRegister(
      AttendanceRegisterDTO dto, String token) async {
    final response = await apiClient.get(
      "TeamMgmt/GetAttendanceRegister",
      queryParameters: dto.toQuery(),
      headers: {"Authorization": token},
    );

    return AttendanceRegisterResponse.fromJson(response);
  }

  Future<HolidaysResponse> getHolidayList(HolidaysDTO dto, String token) async {
    final response = await apiClient.get(
      "TeamMgmt/GetHolidaysList",
      queryParameters: dto.toQuery(),
      headers: {"Authorization": token},
    );

    return HolidaysResponse.fromJson(response);
  }

  Future<UserDetailsResponse> getUserDetails(UserDetailsDTO dto,
      String token) async {
    final response = await apiClient.get(
      "TeamMgmt/GetUserDetails",
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
      "TeamMgmt/SaveAttandance",
      queryParameters: {"UserId": userId},
      body: dto.toJson(),
      headers: {"Authorization": token},
    );
    return AttendanceMarkedResponse.fromJson(response);
  }

  Future<ViewMasterAttendanceResponse> getMasterAttendanceRegister(
      AttendanceRegisterDTO dto, String token) async {
    final response = await apiClient.get(
      "TeamMgmt/GetMasterAttendance",
      queryParameters: dto.toQuery(),
      headers: {"Authorization": token},
    );

    return ViewMasterAttendanceResponse.fromJson(response);
  }

  Future<SummaryAttendanceResponse> getSummaryAttendance(
      AttendanceRegisterDTO dto, String token) async {
    final response = await apiClient.get(
      "TeamMgmt/GetSummarizedAttendance",
      queryParameters: dto.toQuery(),
      headers: {"Authorization": token},
    );
    return SummaryAttendanceResponse.fromJson(response);
  }

  Future<SummaryAttendanceDashboardResponse> getSummaryAttendanceDashboard(
      AttendanceRegisterDTO dto, String token) async {
    final response = await apiClient.get(
      "TeamMgmt/GetSummarizedAttendanceDashboard",
      queryParameters: dto.toQuery(),
      headers: {"Authorization": token},
    );
    return SummaryAttendanceDashboardResponse.fromJson(response);
  }





}

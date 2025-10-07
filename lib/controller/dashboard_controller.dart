import 'dart:io';

import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tms/dto/common_api_dto.dart';
import 'package:tms/dto/update_fcm_token_dto.dart';
import 'package:tms/response/summary_attendance_dashboard_response.dart';
import 'package:tms/utils/pref_constant.dart';
import '../api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../dto/attendance_register_dto.dart';


class DashboardController extends GetxController {
  var isLoading = false.obs;
  var summaryAttendanceList = <summaryAttendanceDashoardItem>[].obs;
  final api = ApiService();
  var AppId = "123456789";

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

  Future<void> updateFCMToken(String userId,UpdateFcmTokenDto dto, String token) async {
    try {
      isLoading.value = true;

      // Call API (make sure your api service returns MasterAttendanceResponse)
      final response = await api.updateFCMToken(userId: userId,dto: dto,token: token);

      if (response != null && response.items != null) {
        if(response.items[0].Result=="true"){
          print("FCM Token updated successfully");
        }else{
          print("FCM Token update failed");
        }
        // Clear existing list
        // summaryAttendanceList.clear();
        // Add new items
        // summaryAttendanceList.addAll(response.items!.whereType<summaryAttendanceDashoardItem>());
      }
    } catch (e) {
      // summaryAttendanceList.clear();
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkVersionAPI(CommonApiDto dto) async {
    try {
      isLoading.value = true;
      final packageInfo = await PackageInfo.fromPlatform();
      final fullVersion = packageInfo.version; // e.g. "6.0.0"
      final majorVersion = fullVersion.split('.').first; // e.g. "6"

      final response = await api.getFixedParameter(dto);

      if (response != null && response.items != null) {
        final String versionResponse = response.items[0].Description ?? "";

        //Compare major version (or use fullVersion if server returns full version)
        if (versionResponse != majorVersion) {
          
          final response = await api.getFixedParameter(CommonApiDto(strCode: packageInfo.packageName, strType: PrefConstant.APPSTOREAPPID));

          if (response != null && response.items != null) {
            AppId = response.items[0].Description ?? "123456789";
          }
          // Show update dialog
          Get.dialog(
            Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // header background
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2B2D42), // match your theme background
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(
                              Icons.system_update_alt,
                              color: Colors.blueAccent,
                              size: 42,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "New Version Available",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Column(
                        children: [
                          Text(
                            "A newer version ($versionResponse) of this app is available.\nYou are currently using version $majorVersion.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 15, color: Colors.black87),
                          ),
                          const SizedBox(height: 28),

                          // Update button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () async {
                                final storeUrl = Platform.isAndroid
                                    ? "https://play.google.com/store/apps/details?id=${packageInfo.packageName}"
                                    : "https://apps.apple.com/app/id${AppId}"; // must replace the id1234567890 with your actual App Store ID

                                final Uri url = Uri.parse(storeUrl);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                } else {
                                  Get.snackbar("Error", "Could not open the store link.");
                                }
                              },
                              child: const Text(
                                "Update Now",
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            barrierDismissible: false,
          );
        }
      } else {
        Get.snackbar("No Data", "No version info found from server.");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }


}


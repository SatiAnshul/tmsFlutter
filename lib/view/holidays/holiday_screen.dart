import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms/controller/holidays_controller.dart';
import 'package:tms/dto/holidays_dto.dart';

class ViewHolidayScreen extends StatefulWidget {
  const ViewHolidayScreen({super.key});

  @override
  State<ViewHolidayScreen> createState() => ViewHolidayScreenState();
}


class ViewHolidayScreenState extends State<ViewHolidayScreen> {
  final controller = Get.put(HolidaysController());
  String? fullVersion;
  String? majorVersion;
  String? appName;

  void _loadData() async {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id") ?? "";
      final token = prefs.getString("auth_token") ?? "";
      final dto = HolidaysDTO(
        userId: userId, // TODO: replace with SharedPrefs userId
        APPVersion: majorVersion!,
        APPName: appName!,
      );
      // TODO: load from SharedPrefs
      await controller.fetchHoliday(dto, "Bearer $token");
    // else {
    //   Get.snackbar("Error", "Please select both dates");
    // }
  }
  @override
  void initState()  {
    super.initState();
    _initData();
  }
  Future<void> _initData() async {
    final packageInfo = await PackageInfo.fromPlatform();
    fullVersion = packageInfo.version; // "6.0.0"
    majorVersion = fullVersion?.split('.').first; // "6"
    appName = packageInfo.packageName; // e.g. "com.tecxpert.tms"
    _loadData();  //
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Holidays List"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Get.back();
          },
        ),
      ),
      body:
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFDAE9F4),
              Color(0xFFC0DCEA),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildHolidayTable(),
        ),
      ),
    );
  }

  Widget _buildHolidayTable(){
    return Padding(
      padding: const EdgeInsets.all(24),

      child: Column(spacing: 10,crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Table header
          Container(
              // color: Color(0xFF0894DA),
              decoration: BoxDecoration(
                color: const Color(0xFF0894DA), // background color
                border: Border.all(
                  color: const Color(0xFF053B6B), // dark blue stroke
                  width: 2, // thickness of the stroke
                ),
                borderRadius: BorderRadius.circular(12), // rounded corners
              ),
              child:
              Row(
                children: const [
                  Expanded(child: Text("Date", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16),textAlign: TextAlign.center,)),
                  Expanded(child: Text("Day", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16),textAlign: TextAlign.center)),
                  Expanded(child: Text("Occasion", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16),textAlign: TextAlign.center)),
                ],
              )
          ),


          const Divider(),

          // List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.holidayList.isEmpty) {
                return const Center(child: Text("No data found"));
              }
              return ListView.builder(
                itemCount: controller.holidayList.length,
                itemBuilder: (context, index) {
                  final item = controller.holidayList[index];
                  return
                    Container(
                        // color: Color(0xFFD6E9F3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3), // background color
                          border: Border.all(
                            color: const Color(0xFF053B6B), // dark blue stroke
                            width: 2, // thickness of the stroke
                          ),
                          borderRadius: BorderRadius.circular(12), // rounded corners
                        ),
                        child:
                        Row(
                            children: [
                              Expanded(child: Text(item.HolidayDate ?? "N/A",textAlign: TextAlign.center,style: TextStyle(color:Colors.black,fontSize: 14,fontWeight: FontWeight.w200),)),
                              Expanded(child: Text(item.Day ?? "N/A",textAlign: TextAlign.center,style: TextStyle(color:Colors.black,fontSize: 14,fontWeight: FontWeight.w200))),
                              Expanded(child: Text(item.Occasion ?? "N/A",textAlign: TextAlign.center,style: TextStyle(color:Colors.black,fontSize: 14,fontWeight: FontWeight.w200))),
                            ]
                        )
                    );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

}

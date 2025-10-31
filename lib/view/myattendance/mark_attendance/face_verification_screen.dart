import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tms/controller/attendance_mark_controller.dart';

class FaceVerificationScreen extends StatefulWidget {
  const FaceVerificationScreen({super.key});

  @override
  State<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen> {
  CameraController? _cameraController;
  final AttendanceMarkController controller = Get.put(AttendanceMarkController());
  bool _isCameraInitialized = false;
  String? _uploadedImageId;
  bool _isLoading = false;
  String? currentLat;
  String? currentLong;
  bool locationCheck = false;


  @override
  void initState() {
    super.initState();
    //_initializeCamera();
    _checkGpsAndPermissions();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (mounted) {
      setState(() => _isCameraInitialized = true);
    }
  }

  /// Capture + Upload
  Future<void> _captureAndUpload() async {
    if (!_cameraController!.value.isInitialized) return;

    try {
      setState(() => _isLoading = true);

      // Take picture
      final XFile rawImage = await _cameraController!.takePicture();
      final File originalFile = File(rawImage.path);

      // Compress
      final File compressedFile = await _compressImage(originalFile);

      // Upload to API
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id") ?? "";
      final token = prefs.getString("auth_token") ?? "";

      final response = await _uploadImage(
        file: compressedFile,
        appUserCode: userId,
        userId: userId,
        token: "Bearer $token",
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json["result"].toString() == "true") {
          controller.attendanceMarking(currentLat ?? "0.00", currentLong ?? "0.00", json["data"]![0]!["File_Info"].toString(), "IOS DEVICE");
          setState(() {
            // _uploadedImageId =
            //     json["data"]?[0]?["File_Info"]?.toString() ?? "";
            Get.back();
            Get.snackbar("Attendance Marked", "Successfully");
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Upload failed: ${json["Message"]}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode}")),
        );
      }

      // Always cleanup
      if (originalFile.existsSync()) await originalFile.delete();
      if (compressedFile.existsSync() &&
          compressedFile.path != originalFile.path) {
        await compressedFile.delete();
      }
    } catch (e) {
      debugPrint("Upload error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Multipart POST (with query params)
  Future<http.Response> _uploadImage({
    required File file,
    required String appUserCode,
    required String userId,
    required String token,
  }) async {
    final uri = Uri.parse(
      "http://103.47.149.49:6550/api/TeamMgmt/FileUpload",
    ).replace(queryParameters: {
      "AppUserCode": appUserCode,
      "UserId": userId,
    });

    final request = http.MultipartRequest("POST", uri)
      ..headers["Authorization"] = token
      ..fields["data"] = "Test"
      ..files.add(await http.MultipartFile.fromPath("file", file.path));

    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  /// Check if GPS (location services) is enabled
  Future<void> _checkGpsAndPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showGpsDialog();
      locationCheck = false;
      return;
    }

    // Request both camera and location permissions
    await _checkAllPermissions();
  }

  Future<void> _checkAllPermissions() async {
    // Request Camera permission (for both Android & iOS)
    var cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      cameraStatus = await Permission.camera.request();
    }

    // Request Location permission
    var locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
    }

    if (cameraStatus.isGranted &&
        (locationPermission == LocationPermission.always ||
            locationPermission == LocationPermission.whileInUse)) {
      locationCheck = true;
      await _getLocation();
      await _initializeCamera();
    } else {
      locationCheck = false;
      _showPermissionDialog();
    }
  }

  /// Fallback dialog if user denies permissions
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Permissions required"),
        content: const Text(
            "Camera and location permissions are required to mark attendance."),
        actions: [
          TextButton(
            onPressed: () => openAppSettings(),
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  /// Check and request location permissions
  Future<void> _checkLocationPermissions() async {
    var status = await Permission.location.status;
    if (status.isGranted) {
      locationCheck = true;
      await _getLocation();
      _initializeCamera();
    } else if (status.isDenied) {
      // Request permission
      if (await Permission.location.request().isGranted) {
        locationCheck = true;
        _initializeCamera();
        await _getLocation();
      } else {
        locationCheck = false;
      }
    } else if (status.isPermanentlyDenied) {
      // Show dialog to open app settings
      openAppSettings();
    }
  }

  /// Get current coordinates
  Future<void> _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        currentLat = position.latitude.toString();
        currentLong = position.longitude.toString();
      });

      debugPrint("Latitude: $currentLat, Longitude: $currentLong");
    } catch (e) {
      debugPrint("Failed to get location: $e");
    }
  }

  /// Show dialog if GPS is disabled
  void _showGpsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enable GPS"),
        content: const Text("Please enable GPS to continue"),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              Navigator.of(context).pop();
              Geolocator.openLocationSettings();
            },
          ),
        ],
      ),
    );
  }


  /// Compress image using flutter_image_compress
  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        "${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg";

    // In latest flutter_image_compress this is XFile?
    final XFile? result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 45,
    );

    if (result == null) {
      return file; // fallback to original if compression fails
    }

    return File(result.path);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Face Verification"),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Column(
        children: [
          Expanded(
            child: _isCameraInitialized
                ? CameraPreview(_cameraController!)
                : const Center(child: CircularProgressIndicator()),
          ),
          if (_uploadedImageId != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Uploaded Image ID: $_uploadedImageId"),
            ),
          const SizedBox(height: 10),
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
            onPressed: _captureAndUpload,
            child: const Text("Capture & Upload"),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

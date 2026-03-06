import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
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
  bool _isLoading = false;
  String? currentLat;
  String? currentLong;

  @override
  void initState() {
    super.initState();
    // Important for iOS: wait for first frame before asking permissions
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkGpsAndPermissions();
    });
  }


  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint("No cameras found.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No camera available on this device.")),
        );
        return;
      }

      final frontCamera = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(frontCamera, ResolutionPreset.medium, enableAudio: false);
      await _cameraController!.initialize();

      if (mounted) setState(() => _isCameraInitialized = true);
      debugPrint("Camera initialized successfully.");
    } catch (e) {
      debugPrint("Camera init error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Camera failed to start: $e")),
        );
      }
    }
  }


  Future<void> _captureAndUpload() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      setState(() => _isLoading = true);

      final XFile rawImage = await _cameraController!.takePicture();
      final File compressed = await _compressImage(File(rawImage.path));

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id") ?? "";
      final token = prefs.getString("auth_token") ?? "";

      final response = await _uploadImage(
        file: compressed,
        appUserCode: userId,
        userId: userId,
        token: "Bearer $token",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["result"].toString() == "true") {
          controller.attendanceMarking(
            currentLat ?? "0.00",
            currentLong ?? "0.00",
            data["data"]![0]!["File_Info"].toString(),
            Platform.isIOS ? "IOS DEVICE" : "ANDROID DEVICE",
          );
          Get.offAllNamed('/dashboard');
          Get.snackbar("Attendance Marked", "Successfully");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Upload failed: ${data["Message"]}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
      }

      if (compressed.existsSync()) await compressed.delete();
    } catch (e) {
      debugPrint("Capture/upload error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<http.Response> _uploadImage({
    required File file,
    required String appUserCode,
    required String userId,
    required String token,
  }) async {
    final uri = Uri.parse("http://103.47.149.49:6550/api/TeamMgmt/FileUpload")
        .replace(queryParameters: {"AppUserCode": appUserCode, "UserId": userId});

    final request = http.MultipartRequest("POST", uri)
      ..headers["Authorization"] = token
      ..fields["data"] = "Test"
      ..files.add(await http.MultipartFile.fromPath("file", file.path));

    final stream = await request.send();
    return await http.Response.fromStream(stream);
  }

  /// --- PERMISSION CHECKS (camera + while-in-use location only) ---
  Future<void> _checkGpsAndPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showGpsDialog();
      return;
    }
    await _checkAllPermissions();
  }

  Future<void> _checkAllPermissions() async {
    try {
      // Camera
      var cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        _showPermissionDialog("Camera access is required to take your attendance photo.");
        return;
      }

      // Location (while-in-use only)
      var locationPermission = await Geolocator.checkPermission();
      if (locationPermission == LocationPermission.denied ||
          locationPermission == LocationPermission.deniedForever) {
        locationPermission = await Geolocator.requestPermission();
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (locationPermission != LocationPermission.whileInUse &&
          locationPermission != LocationPermission.always) {
        _showPermissionDialog("Location access is required to record your attendance location.");
        return;
      }


      await _getLocation();
      await _initializeCamera();
    } catch (e) {
      debugPrint("Permission error: $e");
      _showPermissionDialog("Permissions are needed to continue.");
    }
  }


  void _showPermissionDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Permission Required"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  void _showGpsDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enable GPS"),
        content: const Text("Please enable GPS to continue."),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }


  Future<void> _getLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        currentLat = pos.latitude.toString();
        currentLong = pos.longitude.toString();
      });
      debugPrint("Latitude: $currentLat, Longitude: $currentLong");
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }


  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = "${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final XFile? result =
    await FlutterImageCompress.compressAndGetFile(file.path, targetPath, quality: 45);
    return result == null ? file : File(result.path);
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
        title: const Text("Attendance Capture"),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isCameraInitialized
                ? CameraPreview(_cameraController!)
                : const Center(child: CircularProgressIndicator()),
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

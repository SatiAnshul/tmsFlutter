import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../../controller/login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginController controller = Get.put(LoginController());
  final userCodeController = TextEditingController();
  final passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
      Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white60,
          // gradient: LinearGradient(
          //   begin: Alignment.topLeft,
          //   end: Alignment.bottomRight,
          //   colors: [
          //     Color(0xFFFFFFFF),
          //     Color(0xFFFFFFFF),
          //     Color(0xFFFFFFFF),
          //     // Color(0xFFEEF2FA),
          //     // Color(0xFFC0DCEA),
          //   ],
          // ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie Animation header
              SizedBox(
                height: 230,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center, // for center the logo
                  children: [
                    // Background wave (rotated 180° like XML)
                    Transform.rotate(
                      angle: 3.14159, // π radians = 180 degrees
                      child: Lottie.asset(
                        'assets/lottie/live_wave_bg.json',
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.fill,
                        repeat: true,
                      ),
                    ),

                    // Center logo
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Image.asset(
                        'assets/images/round_logo.png',
                        height: 140,
                        width: 140,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),


              const SizedBox(height: 24),

              // Login card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: BoxBorder.all(color: Color(0xFF0894DA)),
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF0894DA).withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(2, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0894DA),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // User ID Field
                    TextField(
                      controller: userCodeController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: "Enter Employee ID",
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Password Field with eye toggle
                    TextField(
                      textInputAction: TextInputAction.done,
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: "Enter Password",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Reset password link
                    TextButton(
                      onPressed: () {
                        // TODO: navigate to reset password
                      },
                      child: const Text(
                        "Reset Password?",
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Login Button
                    Obx(() {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            backgroundColor: Color(0xFF0894DA),
                          ),
                          onPressed: controller.isLoading.value
                              ? null
                              : () {
                            controller.login(
                              userCodeController.text.trim(),
                              passwordController.text.trim(),
                            );
                          },
                          icon: const Icon(Icons.login , color: Colors.white,),
                          label: controller.isLoading.value
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            "Login",
                            style: TextStyle(
                                fontSize: 18,fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

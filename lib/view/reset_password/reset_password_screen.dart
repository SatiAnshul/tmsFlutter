import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/reset_password_controller.dart';


class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});


  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final OldPWDController = TextEditingController();
  final NewPWDController = TextEditingController();
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;

  @override
  Widget build(BuildContext context) {
    final ResetPasswordController controller = Get.put(ResetPasswordController());
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password" , textAlign: TextAlign.center),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Get.back();
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // const Text(
              //   "Reset Password",
              //   style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              // ),
              // const SizedBox(height: 24),
              // TextField(
              //   controller: OldPWDController,
              //   obscureText: true,
              //   textInputAction: TextInputAction.next,
              //   decoration: const InputDecoration(
              //     labelText: "Old Password",
              //     border: OutlineInputBorder(),
              //   ),
              // ),
              TextField(
                textInputAction: TextInputAction.next,
                controller: OldPWDController,
                obscureText: _obscureOldPassword,
                decoration: InputDecoration(
                  hintText: "Enter Old Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureOldPassword
                          ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureOldPassword = !_obscureOldPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),
          TextField(
            textInputAction: TextInputAction.done,
            controller: NewPWDController,
            obscureText: _obscureNewPassword,
            decoration: InputDecoration(
              hintText: "Enter New Password",
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureNewPassword = !_obscureNewPassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // TextField(
              //   controller: NewPWDController,
              //   obscureText: true,
              //   decoration: const InputDecoration(
              //     labelText: "New Password",
              //     border: OutlineInputBorder(),
              //   ),
                // onSubmitted: (_) => controller.resetPassword(
                //   OldPWDController.text.trim(),
                //   NewPWDController.text.trim(),
                // ),
              const SizedBox(height: 24),
              Obx(() {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => controller.resetPassword(
                      OldPWDController.text.trim(),
                      NewPWDController.text.trim(),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Submit", style: TextStyle(fontSize: 18)),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}




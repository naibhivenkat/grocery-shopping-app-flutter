import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  
  int _step = 1; // 1=Send OTP, 2=Verify OTP, 3=Update Password
  bool _isLoading = false;
  String _infoText = "";

  // --- LOGIC ---

  Future<void> _handleAction() async {
    setState(() {
      _isLoading = true;
      _infoText = ""; // Clear previous errors
    });

    String email = _emailController.text.trim();
    String otp = _otpController.text.trim();
    String password = _passwordController.text.trim();

    Map<String, dynamic> result;

    if (_step == 1) {
      // Step 1: Send OTP
      if (email.isEmpty) {
        _showError("Enter email first");
        return;
      }
      result = await ApiService.sendPasswordResetOtp(email);
      
      if (result['success'] == true) {
        setState(() {
          _step = 2;
          _infoText = result['message'] ?? "OTP sent to email";
        });
      } else {
        _showError(result['message']);
      }

    } else if (_step == 2) {
      // Step 2: Verify OTP
      if (otp.isEmpty) {
        _showError("Enter OTP");
        return;
      }
      result = await ApiService.verifyPasswordResetOtp(email, otp);
      
      if (result['success'] == true) {
        setState(() {
          _step = 3;
          _infoText = result['message'] ?? "OTP Verified. Set new password.";
        });
      } else {
        _showError(result['message']);
      }

    } else {
      // Step 3: Update Password
      if (password.isEmpty) {
        _showError("Enter new password");
        return;
      }
      result = await ApiService.updatePassword(email, password);
      
      if (result['success'] == true) {
        if(mounted) _showSuccessDialog(result['message'] ?? "Password updated successfully");
      } else {
        _showError(result['message']);
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showError(String? msg) {
    setState(() {
      _isLoading = false;
      _infoText = msg ?? "An error occurred";
    });
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Success 🎉"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Back to Login
            },
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            
            // Info Text (Errors / Success messages)
            if (_infoText.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                color: Colors.blue.shade50,
                child: Text(
                  _infoText,
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),

            // Step 1: Email Field (Always Visible, but disabled after step 1)
            TextField(
              controller: _emailController,
              enabled: _step == 1,
              decoration: const InputDecoration(
                labelText: "Email Address", 
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email)
              ),
            ),
            const SizedBox(height: 16),

            // Step 2: OTP Field (Visible only if step >= 2)
            if (_step >= 2) ...[
              TextField(
                controller: _otpController,
                enabled: _step == 2,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Enter OTP", 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_clock)
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Step 3: New Password Field (Visible only if step == 3)
            if (_step == 3) ...[
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "New Password", 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock)
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Action Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleAction,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text(
                      _step == 1 ? "Send OTP" : (_step == 2 ? "Verify OTP" : "Update Password"),
                      style: const TextStyle(fontSize: 16, color: Colors.white)
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
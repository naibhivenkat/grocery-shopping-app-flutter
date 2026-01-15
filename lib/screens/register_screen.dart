import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart'; // Ensure you ran 'flutter pub add pinput'
import 'package:shared_preferences/shared_preferences.dart';
import 'customer_home_screen.dart'; // Placeholder import
import 'shop_owner_dashboard.dart'; // Placeholder import

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // CONFIG
  final String baseUrl = "https://grocery-backend-956424262985.asia-south1.run.app/"; // Android Emulator
  // final String baseUrl = "http://127.0.0.1:5000"; // iOS Simulator

  // UI STATE
  int _currentStep = 0; // 0 = Form, 1 = OTP
  bool _isLoading = false;
  String? _errorMessage;
  
  // FORM CONTROLLERS
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = "customer"; // Default role

  // OTP STATE
  final _otpController = TextEditingController();
  Timer? _timer;
  int _start = 120; // 2 minutes
  final int _resendAttempts = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- LOGIC: SEND OTP ---
  Future<void> _sendOtp() async {
    // 1. Validate Form
    if (_nameController.text.isEmpty || _emailController.text.isEmpty ||
        _phoneController.text.isEmpty || _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _errorMessage = "Please fill all fields");
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = "Passwords do not match");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 2. API Call
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send_otp'), // Update with your actual endpoint
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": _emailController.text.trim()}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _currentStep = 1; // Move to OTP view
          _start = 120; // Reset timer
          _startTimer();
        });
      } else {
        setState(() => _errorMessage = "Failed to send OTP: ${response.body}");
      }
    } catch (e) {
      setState(() => _errorMessage = "Connection Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- LOGIC: VERIFY OTP & REGISTER ---
  Future<void> _verifyOtpAndRegister() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _errorMessage = "Please enter a 6-digit OTP");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Verify OTP
      final verifyResp = await http.post(
        Uri.parse('$baseUrl/verify_otp'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "otp": otp
        }),
      );

      final verifyData = jsonDecode(verifyResp.body);
      
      if (verifyResp.statusCode == 200 && verifyData['status'] == 'success') {
        // 2. Final Registration
        await _finalRegistration();
      } else {
        setState(() => _errorMessage = "Invalid OTP");
      }
    } catch (e) {
      setState(() => _errorMessage = "Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _finalRegistration() async {
    final body = {
      "full_name": _nameController.text.trim(),
      "username": _usernameController.text.trim(),
      "email": _emailController.text.trim(),
      "phone": _phoneController.text.trim(),
      "role": _selectedRole,
      "password": _passwordController.text.trim(),
    };

    final regResp = await http.post(
      Uri.parse('$baseUrl/register_after_otp'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    final regData = jsonDecode(regResp.body);

    if (regResp.statusCode == 200 && regData['success'] == true) {
      // SAVE DATA (Session)
      await _saveSessionData(regData);
      
      // NAVIGATE
      if (!mounted) return;
      if (_selectedRole == "customer") {
        // Navigate to Customer Home
        Navigator.pushReplacementNamed(context, '/customer_home');
      } else {
        // Navigate to Shop Owner Home
        Navigator.pushReplacementNamed(context, '/shop_owner_home');
      }
    } else {
      setState(() => _errorMessage = "Registration Failed: ${regData['message']}");
    }
  }

  Future<void> _saveSessionData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final user = data['user'];
    
    if (data['token'] != null) await prefs.setString('auth_token', data['token']);
    if (user['username'] != null) await prefs.setString('username', user['username']);
    if (user['role'] != null) await prefs.setString('role', user['role']);
    
    // Save IDs based on role
    if (user['customerId'] != null) await prefs.setString('customerId', user['customerId']);
    if (user['shopkeeperId'] != null) await prefs.setString('shopkeeperId', user['shopkeeperId']);
  }

  // --- UTILS: TIMER ---
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  // --- UI: BUILDER ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _currentStep == 0 ? _buildForm() : _buildOtpView(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_errorMessage != null) 
          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
        
        TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Full Name")),
        TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
        TextField(controller: _phoneController, decoration: const InputDecoration(labelText: "Phone")),
        TextField(controller: _usernameController, decoration: const InputDecoration(labelText: "Username")),
        
        // Role Dropdown
        DropdownButtonFormField<String>(
          initialValue: _selectedRole,
          items: const [
            DropdownMenuItem(value: "customer", child: Text("Customer")),
            DropdownMenuItem(value: "shopowner", child: Text("Shop Owner")),
          ],
          onChanged: (val) => setState(() => _selectedRole = val!),
          decoration: const InputDecoration(labelText: "I am a..."),
        ),
        
        TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password")),
        TextField(controller: _confirmPasswordController, obscureText: true, decoration: const InputDecoration(labelText: "Confirm Password")),
        
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendOtp,
          child: _isLoading ? const CircularProgressIndicator() : const Text("Send OTP"),
        ),
      ],
    );
  }

  Widget _buildOtpView() {
    return Column(
      children: [
        const Text("Enter the code sent to your email", style: TextStyle(fontSize: 16)),
        const SizedBox(height: 20),
        
        // OTP BOXES (Requires 'pinput' package)
        Pinput(
          length: 6,
          controller: _otpController,
          defaultPinTheme: PinTheme(
            width: 50, height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        Text("Time remaining: ${_start ~/ 60}:${(_start % 60).toString().padLeft(2, '0')}"),
        
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isLoading || _start == 0 ? null : _verifyOtpAndRegister,
          child: _isLoading ? const CircularProgressIndicator() : const Text("Verify & Register"),
        ),

        TextButton(
          onPressed: _start == 0 && _resendAttempts < 3 ? () {
             // Add resend logic here
          } : null, 
          child: const Text("Resend OTP"),
        ),
      ],
    );
  }
}
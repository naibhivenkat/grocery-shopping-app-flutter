import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/session_manager.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final String baseUrl =
      "https://grocery-backend-956424262985.asia-south1.run.app/";

  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = "customer";

  final _otpController = TextEditingController();
  Timer? _timer;
  int _start = 120;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ───────────────── SEND OTP ─────────────────
  Future<void> _sendOtp() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _usernameController.text.isEmpty ||
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

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send_otp'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": _emailController.text.trim()}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _currentStep = 1;
          _start = 120;
          _startTimer();
        });
      } else {
        setState(() => _errorMessage = "Failed to send OTP");
      }
    } catch (e) {
      setState(() => _errorMessage = "Connection error");
    }

    setState(() => _isLoading = false);
  }

  // ───────────────── VERIFY OTP ─────────────────
  Future<void> _verifyOtpAndRegister() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      setState(() => _errorMessage = "Enter valid OTP");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
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
        await _finalRegistration();
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = "Invalid OTP";
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Verification error";
      });
    }
  }

  // ───────────────── FINAL REGISTRATION ─────────────────
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

    print("REGISTER STATUS: ${regResp.statusCode}");
    print("REGISTER BODY: ${regResp.body}");

    final regData = jsonDecode(regResp.body);

    // 🔥 ACCEPT 200 + 201
    if ((regResp.statusCode == 200 || regResp.statusCode == 201)
        && regData['success'] == true) {

      await _saveSessionData(regData);

      final user = regData['user'];
      final role = user['role'];

      if (!mounted) return;

      
      if (role == 'shopowner' || role == 'shopkeeper') {

        // 🔥 ALWAYS go to dashboard first
        Navigator.pushReplacementNamed(context, '/shop_owner_home');

      } else {

        Navigator.pushReplacementNamed(context, '/customer_home');

      }


      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = "Registration failed";
    });
  }

  // ───────────────── SAVE SESSION ─────────────────
Future<void> _saveSessionData(Map<String, dynamic> data) async {
  final user = data['user'];
  final token = data['token'];

  // 🔐 use SAME storage as login flow
  await SessionManager.saveLogin(
    user['username'] ?? "",
    user['role'] ?? "",
  );

  await SessionManager.setAuthToken(token ?? "");

  if (user['shopkeeperId'] != null) {
    await SessionManager.setShopkeeperId(user['shopkeeperId']);
  }

  if (user['customerId'] != null) {
    await SessionManager.setCustomerId(user['customerId']);
  }
}

  // ───────────────── TIMER ─────────────────
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        timer.cancel();
      } else {
        setState(() => _start--);
      }
    });
  }

  // ───────────────── UI ─────────────────
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
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text("Send OTP"),
        ),
      ],
    );
  }

  Widget _buildOtpView() {
    return Column(
      children: [
        const Text("Enter OTP sent to your email"),
        const SizedBox(height: 20),

        Pinput(length: 6, controller: _otpController),

        const SizedBox(height: 20),

        Text("Time remaining: ${_start ~/ 60}:${(_start % 60).toString().padLeft(2, '0')}"),

        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: _isLoading ? null : _verifyOtpAndRegister,
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text("Verify & Register"),
        ),
      ],
    );
  }
}


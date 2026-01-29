import 'package:flutter/material.dart';
import '../api/service_api.dart';
import '../utils/provider_theme.dart';
import '../utils/ui_helpers.dart';
import '../utils/validators.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _newPass = TextEditingController();
  final _otp = TextEditingController();

  bool _otpSent = false;
  bool _otpVerified = false;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _newPass.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (Validators.email(_email.text) != null) {
      UIHelpers.showSnack(context, "Enter valid email", error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await ServiceApi.sendOtp(email: _email.text.trim()); // ✅ no purpose
      setState(() => _otpSent = true);
      UIHelpers.showSnack(context, "OTP sent ✅");
    } catch (e) {
      UIHelpers.showSnack(
        context,
        e.toString().replaceFirst("Exception: ", ""),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() => _loading = true);
    try {
      await ServiceApi.verifyOtp(
        email: _email.text.trim(),
        otp: _otp.text.trim(),
      ); // ✅ no purpose

      setState(() => _otpVerified = true);
      UIHelpers.showSnack(context, "OTP verified ✅");
    } catch (e) {
      UIHelpers.showSnack(
        context,
        e.toString().replaceFirst("Exception: ", ""),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    if (!_form.currentState!.validate()) return;
    if (!_otpVerified) {
      UIHelpers.showSnack(context, "Verify OTP first", error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await ServiceApi.forgotPassword(
        email: _email.text.trim(),
        newPassword: _newPass.text,
      );

      if (!mounted) return;
      UIHelpers.showSnack(context, "Password updated ✅ Please login");
      Navigator.pop(context);
    } catch (e) {
      UIHelpers.showSnack(
        context,
        e.toString().replaceFirst("Exception: ", ""),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ProviderTheme.themeData(),
      child: Scaffold(
        appBar: AppBar(title: const Text("Forgot Password")),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _form,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: "Email"),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _newPass,
                      decoration: const InputDecoration(labelText: "New Password"),
                      obscureText: true,
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _sendOtp,
                        child: const Text("Send OTP"),
                      ),
                    ),
                    if (_otpSent) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _otp,
                        decoration: const InputDecoration(labelText: "Enter OTP"),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _verifyOtp,
                          child: Text(_otpVerified ? "OTP Verified ✅" : "Verify OTP"),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _reset,
                        child: const Text("Reset Password"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

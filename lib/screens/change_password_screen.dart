import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _oldPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final username = await SessionManager.getUsername();
    if (username == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Session Error. Please login again.")));
      return;
    }

    final result = await ApiService.changePassword(
      username,
      _oldPassController.text.trim(),
      _newPassController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password changed successfully")));
        Navigator.pop(context); // Go back
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message']?.toString() ?? "Error changing password"), 
          backgroundColor: Colors.red
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Password"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildPasswordField(_oldPassController, "Old Password"),
              const SizedBox(height: 16),
              _buildPasswordField(_newPassController, "New Password"),
              const SizedBox(height: 16),
              _buildPasswordField(_confirmPassController, "Confirm New Password", isConfirm: true),
              
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator()) 
                  : ElevatedButton(
                      onPressed: _handleChangePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text("CHANGE PASSWORD", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, {bool isConfirm = false}) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.green),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "Please enter password";
        if (value.length < 4) return "Password must be at least 4 characters";
        if (isConfirm && value != _newPassController.text) return "Passwords do not match";
        return null;
      },
    );
  }
}
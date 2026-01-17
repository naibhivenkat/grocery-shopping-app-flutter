import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../services/session_manager.dart';
import '../services/notification_service.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'shop_owner_dashboard.dart';
import 'customer_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = "";

  String _selectedRole = "customer";

  final String baseUrl =
      "https://grocery-backend-956424262985.asia-south1.run.app";

  Future<void> _handleLogin() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Please enter username and password");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final user = data['user'];
        final String serverRole = (user['role'] ?? "").toLowerCase().trim();

        // Role mismatch check
        if (serverRole != _selectedRole) {
          setState(() => _errorMessage =
              "This account is a $serverRole. Please switch the tab above.");
          return;
        }

        // ✅ 1) Save Token
        if (data['token'] != null) {
          await SessionManager.setAuthToken(data['token']);
        }

        // ✅ 2) Save Basic Login
        await SessionManager.saveLogin(user['username'] ?? "", serverRole);

        // ✅ 3) Save FULL PROFILE (THIS FIXES PHOTO NOT SHOWING AFTER RELOGIN)
        await SessionManager.saveUserProfileFull(
          fullName: user['fullName'] ?? user['full_name'] ?? "",
          email: user['email'] ?? "",
          phone: user['phone'] ?? "",
          address: user['address'] ?? "",
          location: user['location'] ?? "",
          photoUrl: user['photoUrl'] ?? user['photo_url'] ?? "",
          photoBase64: user['photoBase64'] ?? user['photo_base64'] ?? "",
        );

        // ✅ 4) Save Role IDs
        if (user['shopkeeperId'] != null) {
          await SessionManager.setShopkeeperId(user['shopkeeperId'].toString());
        }
        if (user['customerId'] != null) {
          await SessionManager.setCustomerId(user['customerId'].toString());
        }
        if (user['firebaseId'] != null) {
          await SessionManager.setFirebaseId(user['firebaseId'].toString());
        }

        // ✅ 5) Save Shop Info
        if (user['shop'] != null) {
          final shopData = user['shop'];
          final String? shopId = shopData['id'];
          final String? shopName = shopData['name'];

          if (shopId != null) {
            await SessionManager.setShopInfo(shopId, shopName ?? "My Shop");
            bool hasItems = user['hasItems'] ?? true;
            await SessionManager.setHasItemsAdded(hasItems);
          }
        }

        // ✅ 6) Register FCM Token
        await NotificationService.checkAndUploadToken();

        if (!mounted) return;

        // ✅ 7) Navigate
        if (serverRole == 'shopowner' || serverRole == 'shopkeeper') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ShopOwnerDashboardScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
          );
        }
      } else {
        setState(() => _errorMessage = data['message'] ?? "Login failed");
      }
    } catch (e) {
      setState(() => _errorMessage = "Connection Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  height: 180,
                  width: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.asset(
                        'assets/app_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Welcome Back",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 30),

              // ROLE TOGGLE
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildRoleButton("Customer", "customer")),
                    Expanded(child: _buildRoleButton("Shop Owner", "shopowner")),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24),

              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  color: Colors.red.shade50,
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedRole == 'shopowner'
                            ? Colors.blueAccent
                            : Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        "LOGIN AS ${_selectedRole.toUpperCase()}",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

              const SizedBox(height: 20),

              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen()));
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                        color: Color.fromARGB(255, 70, 58, 247), fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account?",
                    style: TextStyle(
                        color: Color.fromARGB(135, 5, 5, 5), fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()));
                    },
                    child: Text(
                      "Register Now",
                      style: TextStyle(
                        color: _selectedRole == 'shopowner'
                            ? Colors.blueAccent
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(String title, String roleValue) {
    bool isSelected = _selectedRole == roleValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = roleValue;
          _errorMessage = "";
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
              : [],
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }
}

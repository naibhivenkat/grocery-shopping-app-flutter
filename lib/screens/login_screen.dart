import 'package:firebase_messaging/firebase_messaging.dart';
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
  final String defaultRole;
  const LoginScreen({super.key, this.defaultRole = "customer"});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = "";

  // ✅ only grocery roles here
  late String _selectedRole;

  final String baseUrl =
      "https://grocery-backend-956424262985.asia-south1.run.app";

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.defaultRole;
  }

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
        final user = data['user'] ?? {};
        final String serverRole = (user['role'] ?? "").toLowerCase().trim();

        // ✅ Role mismatch check
        if (serverRole != _selectedRole) {
          setState(() => _errorMessage =
              "This account is a $serverRole. Please login using correct role.");
          return;
        }

        // ✅ Save token
        if (data['token'] != null) {
          await SessionManager.setAuthToken(data['token']);
        }

        // ✅ Save login
        await SessionManager.saveLogin(user['username'] ?? "", serverRole);
        await SessionManager.setServiceUserId(user["uid"]);
        await NotificationService.checkAndUploadToken();
        String? token = await FirebaseMessaging.instance.getToken();
        print("🔥 DEVICE FCM TOKEN = $token");


        // ✅ Save profile
        await SessionManager.saveUserProfileFull(
          fullName: user['fullName'] ?? user['full_name'] ?? "",
          email: user['email'] ?? "",
          phone: user['phone'] ?? "",
          address: user['address'] ?? "",
          location: user['location'] ?? "",
          photoUrl: user['photoUrl'] ?? user['photo_url'] ?? "",
          photoBase64: user['photoBase64'] ?? user['photo_base64'] ?? "",
        );

        // ✅ Save IDs
        if (user['shopkeeperId'] != null) {
          await SessionManager.setShopkeeperId(user['shopkeeperId'].toString());
        }
        if (user['customerId'] != null) {
          await SessionManager.setCustomerId(user['customerId'].toString());
        }
        if (user['firebaseId'] != null) {
          await SessionManager.setFirebaseId(user['firebaseId'].toString());
        }

        // ✅ Shop info
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

        // ✅ Register FCM token
        await NotificationService.checkAndUploadToken();

        if (!mounted) return;

        // ✅ Navigate
        if (serverRole == 'shopowner' || serverRole == 'shopkeeper') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (ctx) => const ShopOwnerDashboardScreen(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (ctx) => const CustomerHomeScreen(),
            ),
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
    final title = _selectedRole == "shopowner" ? "Shop Owner Login" : "Customer Login";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  height: 150,
                  width: 150,
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
              const SizedBox(height: 24),

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
                        backgroundColor:
                            _selectedRole == "shopowner" ? Colors.blueAccent : Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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

              const SizedBox(height: 14),

              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: Color.fromARGB(255, 70, 58, 247),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account?",
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "Register Now",
                      style: TextStyle(
                        color: _selectedRole == "shopowner"
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
}

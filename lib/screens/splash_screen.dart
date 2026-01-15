import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'shop_owner_dashboard.dart'; 
import 'customer_home_screen.dart'; // ✅ 1. UNCOMMENTED THIS

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // CONFIGURATION: 
  // You can change this to "customer" if you want the text to say "Welcome to Customer App"
  final String appRole = "shopowner"; 

  @override
  void initState() {
    super.initState();
    _checkLoginAndNavigate();
  }

  Future<void> _checkLoginAndNavigate() async {
    // 1. Wait 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    // 2. Check Session
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');
    final String? role = prefs.getString('role');

    if (!mounted) return;

    // 3. Navigate
    if (token != null && token.isNotEmpty) {
      if (role == 'shopowner') {
        // GO TO SHOP DASHBOARD
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const ShopOwnerDashboardScreen())
        );
      } else if (role == 'customer') {
        // ✅ 2. ENABLED CUSTOMER NAVIGATION
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const CustomerHomeScreen())
        );
      } else {
        // Unknown role -> Login
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const LoginScreen())
        );
      }
    } else {
      // Not logged in -> Login
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => const LoginScreen())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String welcomeText = "Welcome to Grocery App";
    if (appRole == "customer") welcomeText = "Welcome to Customer App";
    if (appRole == "shopowner") welcomeText = "Welcome to Shop Owner App";

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            Text(
              welcomeText,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator()
          ],
        ),
      ),
    );
  }
}

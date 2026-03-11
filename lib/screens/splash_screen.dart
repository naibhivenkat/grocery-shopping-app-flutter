import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'customer_home_screen.dart';
import 'shop_owner_dashboard.dart';
import 'role_grid_screen.dart';
import '../service_module/provider/screens/service_login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginAndNavigate();
  }

  Future<void> _checkLoginAndNavigate() async {
    // ✅ splash delay
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');
    final String? role = prefs.getString('role');

    if (!mounted) return;

    // ✅ Logged in
    if (token != null && token.isNotEmpty && role != null && role.isNotEmpty) {
      if (role == 'shopowner' || role == 'shopkeeper') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (ctx) => const ShopOwnerDashboardScreen(),
          ),
        );
        return;
      }

      if (role == 'customer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (ctx) => const CustomerHomeScreen(),
          ),
        );
        return;
      }

      // ✅ Service module role
      if (role == 'services') {
        // ✅ For now: open service login screen
        // Later you can auto-direct to ProviderHomeDashboard if you store providerId locally.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (ctx) => const ServiceLoginScreen(),
          ),
        );
        return;
      }

      // unknown role -> role selection
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (ctx) => const RoleGridScreen(),
        ),
      );
      return;
    }

    // ✅ Not logged in -> Role grid
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (ctx) => const RoleGridScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              "Welcome to Grocery App",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'session_manager.dart';
import '../screens/role_grid_screen.dart';

class LogoutHelper {
  static Future<void> logoutAndGoToRoleSelect(BuildContext context) async {
    // ✅ Clear everything
    await SessionManager.logout();

    if (!context.mounted) return;

    // ✅ Go to Role selection screen (remove all previous pages)
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (ctx) => const RoleGridScreen()),
      (route) => false,
    );
  }
}

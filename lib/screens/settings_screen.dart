import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/session_manager.dart';
import 'language_selection_screen.dart';
import 'change_password_screen.dart';
import 'role_grid_screen.dart';

// Placeholder screen
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(title)));
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _username = "Loading...";
  String _role = "Loading...";
  String _version = "";

  final String updateUrl =
      "https://grocery-backend-956424262985.asia-south1.run.app/check_update";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final username = await SessionManager.getUsername() ?? "Unknown";
    final role = await SessionManager.getRole() ?? "Unknown";
    final packageInfo = await PackageInfo.fromPlatform();

    if (!mounted) return;

    setState(() {
      _username = username;
      _role = role[0].toUpperCase() + role.substring(1);
      _version = packageInfo.version;
    });
  }

  // ---------------- ABI DETECTION ----------------
  Future<String> _getDeviceAbi() async {
    if (!Platform.isAndroid) return "";

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;

    // Preferred ABI is always first
    return androidInfo.supportedAbis.first;
  }

  // ---------------- LOGOUT ----------------
  Future<void> _handleLogout() async {
    await SessionManager.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleGridScreen()),
      (_) => false,
    );
  }

  // ---------------- UPDATE CHECK ----------------
  Future<void> _checkForUpdates() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final abi = await _getDeviceAbi();

      final uri = Uri.parse(updateUrl).replace(queryParameters: {
        "platform": "android",
        "abi": abi,
      });

      final response = await http.get(uri);
      Navigator.pop(context);

      if (response.statusCode != 200) {
        _showToast("Failed to check updates");
        return;
      }

      final data = jsonDecode(response.body);

      final int latestCode = data["versionCode"];
      final String latestName = data["versionName"];
      final String apkUrl = data["apkUrl"];
      final int apkSize = data["apkSize"];

      final packageInfo = await PackageInfo.fromPlatform();
      final int currentCode = int.parse(packageInfo.buildNumber);

      if (latestCode > currentCode) {
        _showUpdateDialog(latestName, apkUrl, apkSize);
      } else {
        _showToast("App is up to date");
      }
    } catch (e) {
      Navigator.pop(context);
      _showToast("Update check failed");
    }
  }

  // ---------------- UPDATE DIALOG ----------------
  void _showUpdateDialog(String version, String url, int size) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Update Available 🚀"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("New Version: $version"),
            const SizedBox(height: 6),
            Text("Size: ${_formatSize(size)}"),
            const SizedBox(height: 12),
            const Text(
              "A new version is available. Download and install to continue.",
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Later"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _launchUrl(url);
            },
            child: const Text("Download"),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showToast("Could not open download link");
    }
  }

  // ---------------- HELPERS ----------------
  String _formatSize(int bytes) {
    if (bytes <= 0) return "Unknown";
    const units = ["B", "KB", "MB", "GB"];
    double size = bytes.toDouble();
    int i = 0;
    while (size > 1024 && i < units.length - 1) {
      size /= 1024;
      i++;
    }
    return "${size.toStringAsFixed(2)} ${units[i]}";
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Colors.green),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 50, color: Colors.green),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _username,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Role: $_role",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _tile(
                      Icons.lock_outline,
                      "Change Password",
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen(),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    _tile(
                      Icons.language,
                      "Change Language",
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LanguageSelectionScreen(),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    _tile(
                      Icons.system_update,
                      "Software Info / Update",
                      _checkForUpdates,
                      subtitle: "Current Version: $_version",
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text("Log Out"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: _handleLogout,
                ),
              ),
            ),

            const SizedBox(height: 20),
            Text("Version $_version", style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    String? subtitle,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.green),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: Colors.grey))
          : null,
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}

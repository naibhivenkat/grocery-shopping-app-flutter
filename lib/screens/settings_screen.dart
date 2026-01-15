import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/session_manager.dart';
import 'language_selection_screen.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';

// Placeholders for screens not yet migrated
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(title)));
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
  
  // Backend URL for updates
  final String updateUrl = "https://grocery-backend-956424262985.asia-south1.run.app/check_update";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final username = await SessionManager.getUsername() ?? "Unknown";
    final role = await SessionManager.getRole() ?? "Unknown";
    
    // Get App Version
    final packageInfo = await PackageInfo.fromPlatform();

    if (mounted) {
      setState(() {
        _username = username;
        _role = role[0].toUpperCase() + role.substring(1); // Capitalize
        _version = packageInfo.version;
      });
    }
  }

  // --- LOGOUT LOGIC ---
  Future<void> _handleLogout() async {
    await SessionManager.logout();
    if (!mounted) return;
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // --- UPDATE CHECK LOGIC ---
  Future<void> _checkForUpdates() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.get(Uri.parse(updateUrl));
      Navigator.pop(context); // Close loading

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        final int latestCode = data['versionCode'] ?? 0;
        final String latestName = data['versionName'] ?? "Unknown";
        final String apkUrl = data['apkUrl'] ?? "";
        final int sizeBytes = data['apkSize'] ?? 0;

        final packageInfo = await PackageInfo.fromPlatform();
        final int currentCode = int.parse(packageInfo.buildNumber);

        if (latestCode > currentCode) {
          _showUpdateDialog(latestName, apkUrl, sizeBytes);
        } else {
          _showToast("App is up to date");
        }
      } else {
        _showToast("Failed to check updates");
      }
    } catch (e) {
      Navigator.pop(context); // Close loading if error
      _showToast("Error checking updates: $e");
    }
  }

  void _showUpdateDialog(String version, String url, int size) {
    String sizeStr = _formatSize(size);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Update Available 🚀"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("New Version: $version"),
            const SizedBox(height: 5),
            Text("Size: $sizeStr"),
            const SizedBox(height: 10),
            const Text("A new version of the app is available. Please download to continue."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Later"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _launchUrl(url);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("Download"),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showToast("Could not launch $urlString");
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return "Unknown";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = 0;
    double size = bytes.toDouble();
    while (size > 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return "${size.toStringAsFixed(2)} ${suffixes[i]}";
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // --- UI ---
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
            // Profile Header
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
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    "Role: $_role",
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Buttons List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.lock_outline, 
                      title: "Change Password",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
                    ),
                    const Divider(height: 1),
                    _buildSettingsTile(
                      icon: Icons.language, 
                      title: "Change Language",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSelectionScreen())),
                    ),
                    const Divider(height: 1),
                    _buildSettingsTile(
                      icon: Icons.system_update, 
                      title: "Software Info / Update",
                      subtitle: "Current Version: $_version",
                      onTap: _checkForUpdates, // Calls the update logic
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Logout Button
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
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 0,
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

  Widget _buildSettingsTile({required IconData icon, required String title, String? subtitle, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.green),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.grey)) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
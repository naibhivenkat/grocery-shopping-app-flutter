import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/session_manager.dart';
import 'edit_profile_screen.dart'; // Make sure to create this later

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Data variables
  String _fullName = "Loading...";
  String _email = "Loading...";
  String _phone = "Loading...";
  String _address = "Loading...";
  String _location = "Loading..."; // Optional if you have it
  Uint8List? _profileImageBytes; // For Base64 Image

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // Reload data when coming back from Edit Screen
  Future<void> _loadProfileData() async {
    final name = await SessionManager.getFullName() ?? "N/A";
    final email = await SessionManager.getEmail() ?? "N/A";
    final phone = await SessionManager.getPhone() ?? "N/A";
    final address = await SessionManager.getAddress() ?? "N/A";
    // If you store location or photo in SessionManager, load them here
    // Example: final photoBase64 = await SessionManager.getPhotoBase64();

    // Simulating photo load if you have logic for it:
    // if (photoBase64 != null && photoBase64.isNotEmpty) {
    //   try {
    //     _profileImageBytes = base64Decode(photoBase64);
    //   } catch (e) {
    //     print("Error decoding image: $e");
    //   }
    // }

    if (mounted) {
      setState(() {
        _fullName = name;
        _email = email;
        _phone = phone;
        _address = address;
        // _location = location; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER SECTION ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Profile Image
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: _profileImageBytes != null
                        ? MemoryImage(_profileImageBytes!)
                        : null,
                    child: _profileImageBytes == null
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _fullName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _email,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- DETAILS CARD ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildProfileItem(Icons.phone, "Phone", _phone),
                      const Divider(),
                      _buildProfileItem(Icons.home, "Address", _address),
                      const Divider(),
                      _buildProfileItem(Icons.location_on, "Location", _location), // Optional
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // --- EDIT BUTTON ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit Profile"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    // Navigate to Edit Screen & Wait for result
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()), 
                      // Replace Placeholder with EditProfileScreen() when ready
                    );
                    // Refresh data upon return
                    _loadProfileData();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget for List Items
  Widget _buildProfileItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
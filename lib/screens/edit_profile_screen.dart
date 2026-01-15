import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/session_manager.dart';
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  // Image Data
  Uint8List? _profileImageBytes;
  String? _selectedImageBase64;
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    // Pre-fill fields (Matches Kotlin onCreate logic)
    _nameController.text = await SessionManager.getFullName() ?? "";
    _emailController.text = await SessionManager.getEmail() ?? "";
    _phoneController.text = await SessionManager.getPhone() ?? "";
    _addressController.text = await SessionManager.getAddress() ?? "";
    
    // Load existing image if any
    String? base64Img = await SessionManager.getPhotoBase64();
    if (base64Img != null && base64Img.isNotEmpty && base64Img != "null") {
      try {
        setState(() {
          _profileImageBytes = base64Decode(base64Img);
        });
      } catch (e) {
        print("Error decoding existing image: $e");
      }
    }
  }

  // --- IMAGE PICKER ---
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _profileImageBytes = bytes;
        _selectedImageBase64 = base64Encode(bytes); // Convert to Base64 for API
      });
    }
  }

  // --- SAVE LOGIC ---
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Show Confirmation Dialog (Matches Kotlin Alert Dialog)
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm"),
        content: const Text("Save changes to profile?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Yes")),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLoading = true);

    // 1. Prepare Data
    String username = await SessionManager.getUsername() ?? "";
    String role = await SessionManager.getRole() ?? "";

    Map<String, String> profileData = {
      "username": username,
      "role": role,
      "name": _nameController.text.trim(),
      "email": _emailController.text.trim(),
      "phone": _phoneController.text.trim(),
      "address": _addressController.text.trim(),
      // "location": _locationController.text, // Add if you have location logic
    };

    if (_selectedImageBase64 != null) {
      profileData["photo_base64"] = _selectedImageBase64!;
    }

    // 2. Call API
    bool success = await ApiService.updateProfile(profileData);

    if (success) {
      // 3. Save Locally
      await SessionManager.saveUserProfileFull(
        _nameController.text,
        _addressController.text,
        _phoneController.text,
        _emailController.text,
        _selectedImageBase64 // Can be null if not changed
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully")));
        Navigator.pop(context); // Go back to Profile Screen
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update profile on server")));
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Image
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: _profileImageBytes != null
                                ? MemoryImage(_profileImageBytes!)
                                : null,
                            child: _profileImageBytes == null
                                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Fields
                    _buildTextField(_nameController, "Full Name", Icons.person),
                    const SizedBox(height: 12),
                    _buildTextField(_emailController, "Email", Icons.email),
                    const SizedBox(height: 12),
                    _buildTextField(_phoneController, "Phone", Icons.phone, isNumber: true),
                    const SizedBox(height: 12),
                    _buildTextField(_addressController, "Address", Icons.home),
                    // Add Location field if needed

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text("SAVE CHANGES", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "Please enter $label";
        return null;
      },
    );
  }
}
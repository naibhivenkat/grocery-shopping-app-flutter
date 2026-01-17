import 'dart:convert';
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
  String? _photoUrl;

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    _nameController.text = await SessionManager.getFullName() ?? "";
    _emailController.text = await SessionManager.getEmail() ?? "";
    _phoneController.text = await SessionManager.getPhone() ?? "";
    _addressController.text = await SessionManager.getAddress() ?? "";

    _photoUrl = await SessionManager.getPhotoUrl();

    String? base64Img = await SessionManager.getPhotoBase64();
    if ((base64Img != null && base64Img.isNotEmpty && base64Img != "null") &&
        (_photoUrl == null || _photoUrl!.isEmpty)) {
      try {
        _profileImageBytes = base64Decode(base64Img);
      } catch (_) {}
    }

    setState(() {});
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
      maxWidth: 600,
      maxHeight: 600,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();

      setState(() {
        _profileImageBytes = bytes;
        _selectedImageBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    bool confirm = await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Confirm"),
            content: const Text("Save changes to profile?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Yes"),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() => _isLoading = true);

    String username = await SessionManager.getUsername() ?? "";
    String role = await SessionManager.getRole() ?? "";

    Map<String, String> profileData = {
      "username": username,
      "role": role,
      "name": _nameController.text.trim(),
      "email": _emailController.text.trim(),
      "phone": _phoneController.text.trim(),
      "address": _addressController.text.trim(),
    };

    if (_selectedImageBase64 != null && _selectedImageBase64!.isNotEmpty) {
      profileData["photo_base64"] = _selectedImageBase64!;
    }

    String? newPhotoUrl = await ApiService.updateProfile(profileData);

    if (newPhotoUrl != null) {
      // ✅ Save updated profile locally (STANDARD)
      await SessionManager.saveUserProfileFull(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        location: await SessionManager.getLocation() ?? "",
        photoUrl: newPhotoUrl.isNotEmpty ? newPhotoUrl : (_photoUrl ?? ""),
        photoBase64: "", // ✅ don't store base64 heavy
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update profile on server")),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? avatarImage;

    if (_profileImageBytes != null) {
      avatarImage = MemoryImage(_profileImageBytes!);
    } else if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      avatarImage = NetworkImage(_photoUrl!);
    } else {
      avatarImage = null;
    }

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
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: avatarImage,
                            child: avatarImage == null
                                ? const Icon(Icons.person,
                                    size: 60, color: Colors.grey)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                        _nameController, "Full Name", Icons.person),
                    const SizedBox(height: 12),
                    _buildTextField(_emailController, "Email", Icons.email),
                    const SizedBox(height: 12),
                    _buildTextField(_phoneController, "Phone", Icons.phone,
                        isNumber: true),
                    const SizedBox(height: 12),
                    _buildTextField(
                        _addressController, "Address", Icons.home),
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
                        child: const Text(
                          "SAVE CHANGES",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isNumber = false}) {
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

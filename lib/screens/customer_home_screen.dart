import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'customer_khata_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'shop_selection_screen.dart';
import 'customer_orders_screen.dart';
import 'wallet_screen.dart';

import 'excel_item_selection_screen.dart';


class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text(title)));
}

// --- MAIN CUSTOMER HOME SCREEN ---
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  String _customerName = "Customer";

  // ✅ Profile Image Support
  String? _photoUrl;
  Uint8List? _photoBytes;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ✅ Load Name + Profile Photo
  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final name =
        prefs.getString('fullName') ?? prefs.getString('username') ?? "Customer";

    // ✅ Try URL first (BEST)
    final url = prefs.getString("photo_url") ?? prefs.getString("photoUrl");

    // ✅ Then try Base64 (BACKUP)
    final base64Image =
        prefs.getString("photo_base64") ?? prefs.getString("photoBase64");

    Uint8List? decodedBytes;

    if (base64Image != null && base64Image.isNotEmpty) {
      try {
        decodedBytes = base64Decode(base64Image);
      } catch (_) {
        decodedBytes = null;
      }
    }

    if (!mounted) return;

    setState(() {
      _customerName = name;
      _photoUrl = (url != null && url.isNotEmpty) ? url : null;
      _photoBytes = decodedBytes;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _buildProfileAvatar() {
    // ✅ 1st Priority: photo_url
    if (_photoUrl != null) {
      return CircleAvatar(
        radius: 30,
        backgroundColor: Colors.white,
        backgroundImage: NetworkImage(_photoUrl!),
        onBackgroundImageError: (_, __) {},
      );
    }

    // ✅ 2nd Priority: Base64
    if (_photoBytes != null) {
      return CircleAvatar(
        radius: 30,
        backgroundColor: Colors.white,
        backgroundImage: MemoryImage(_photoBytes!),
      );
    }

    // ✅ Default icon
    return const CircleAvatar(
      radius: 30,
      backgroundColor: Colors.white,
      child: Icon(Icons.person, color: Colors.green, size: 30),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Grocery App"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),

      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.green),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // ✅ Now Drawer shows uploaded photo
                  _buildProfileAvatar(),
                  const SizedBox(height: 10),
                  Text(
                    "Hello, $_customerName",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ).then((_) {
                  // ✅ Reload after profile update
                  _loadProfile();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Wallet'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WalletScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book),
              title: const Text('My Khata'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomerKhataScreen()),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout',
                  style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.green.shade50,
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      "Welcome, $_customerName!",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Ready to shop? Select a store nearby.",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildDashboardCard(
                    icon: Icons.storefront,
                    label: "Start Shopping",
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ShopSelectionScreen()),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    icon: Icons.shopping_bag_outlined,
                    label: "My Orders",
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CustomerOrdersScreen()),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    icon: Icons.account_balance_wallet,
                    label: "Wallet",
                    color: Colors.purple,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WalletScreen()),
                    ),
                  ),
                  _buildDashboardCard(
                    icon: Icons.menu_book,
                    label: "My Khata",
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CustomerKhataScreen()),
                      );
                    },
                  ),

                  _buildDashboardCard(
  icon: Icons.table_chart,
  label: "Excel Test",
  color: Colors.deepOrange,


onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const ExcelItemSelectionScreen(),
    ),
  );
},
),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

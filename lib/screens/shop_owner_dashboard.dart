import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/session_manager.dart';
import 'login_screen.dart';
import 'create_shop_screen.dart';
import 'add_items_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'shop_analytics_screen.dart';
import 'shop_khata_list_screen.dart';
import 'shop_owner_orders_screen.dart';
import 'shop_owner_wallet_screen.dart';
import 'manage_items_screen.dart';

// Placeholder
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text(title)));
}

class ShopOwnerDashboardScreen extends StatefulWidget {
  const ShopOwnerDashboardScreen({super.key});

  @override
  State<ShopOwnerDashboardScreen> createState() =>
      _ShopOwnerDashboardScreenState();
}

class _ShopOwnerDashboardScreenState extends State<ShopOwnerDashboardScreen> {
  final String baseUrl =
      "https://grocery-backend-956424262985.asia-south1.run.app";

  bool _isLoading = true;
  String _shopName = "My Shop";

  // ✅ Owner Profile Photo + Name
  String _ownerName = "Shop Owner";
  String? _photoUrl;
  Uint8List? _photoBytes;

  @override
  void initState() {
    super.initState();
    _checkShopStatus();
  }

  // ✅ Load Owner Name + Photo (same logic as customer)
  Future<void> _loadOwnerProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final name = prefs.getString("fullName") ??
        prefs.getString("username") ??
        "Shop Owner";

    final url = prefs.getString("photo_url") ?? prefs.getString("photoUrl");
    final base64Img =
        prefs.getString("photo_base64") ?? prefs.getString("photoBase64");

    Uint8List? decodedBytes;
    if (base64Img != null && base64Img.isNotEmpty) {
      try {
        decodedBytes = base64Decode(base64Img);
      } catch (_) {
        decodedBytes = null;
      }
    }

    if (!mounted) return;

    setState(() {
      _ownerName = name;
      _photoUrl = (url != null && url.isNotEmpty) ? url : null;
      _photoBytes = decodedBytes;
    });
  }

  Widget _buildOwnerAvatar() {
    // ✅ 1st priority: URL
    if (_photoUrl != null) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: Colors.white,
        backgroundImage: NetworkImage(_photoUrl!),
        onBackgroundImageError: (_, __) {},
      );
    }

    // ✅ 2nd priority: Base64
    if (_photoBytes != null) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: Colors.white,
        backgroundImage: MemoryImage(_photoBytes!),
      );
    }

    // ✅ fallback icon
    return const CircleAvatar(
      radius: 28,
      backgroundColor: Colors.white,
      child: Icon(Icons.store, color: Colors.blueAccent, size: 28),
    );
  }

  // --- LOGIC: CHECK SHOP & ITEMS ---
  Future<void> _checkShopStatus() async {
    // ✅ Load owner profile first
    await _loadOwnerProfile();

    // 1. Get Basic Info via SessionManager
    final token = await SessionManager.getAuthToken();
    final shopkeeperId = await SessionManager.getShopkeeperId();
    String? shopId = await SessionManager.getShopId();

    // Security Check
    if (token == null || shopkeeperId == null) {
      _forceLogout();
      return;
    }

    // 2. Fetch Shop (if not saved locally)
    if (shopId == null) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/get_shop_by_owner?shopkeeperId=$shopkeeperId'),
          headers: {"Authorization": "Bearer $token"},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['shop'] != null) {
            final shop = data['shop'];
            shopId = shop['id'];
            _shopName = shop['name'] ?? "My Shop";

            // ✅ FIX: Save in session correctly
            await SessionManager.setShopInfo(shopId!, _shopName);
          } else {
            _navigateTo('/create_shop');
            return;
          }
        } else {
          _navigateTo('/create_shop');
          return;
        }
      } catch (e) {
        print("Error fetching shop: $e");
      }
    } else {
      _shopName = await SessionManager.getShopName() ?? "My Shop";
    }

    // 3. Check Items (Inventory)
    if (shopId != null) {
      final prefs = await SharedPreferences.getInstance();
      bool hasItems = prefs.getBool('hasItemsAdded') ?? false;

      if (!hasItems) {
        try {
          final itemResp = await http.get(
            Uri.parse('$baseUrl/api/shops/$shopId/items'),
            headers: {"Authorization": "Bearer $token"},
          );

          if (itemResp.statusCode == 200) {
            final itemData = jsonDecode(itemResp.body);
            final List items = itemData['items'] ?? [];
            if (items.isEmpty) {
              _navigateTo('/add_items');
              return;
            } else {
              await prefs.setBool('hasItemsAdded', true);
            }
          }
        } catch (e) {
          print("Error fetching items: $e");
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateTo(String routeName) {
    if (!mounted) return;

    if (routeName == '/create_shop') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const CreateShopScreen()));
    } else if (routeName == '/add_items') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const AddItemsScreen()));
    }
  }

  Future<void> _forceLogout() async {
    await SessionManager.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // --- UI: DASHBOARD ---
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_shopName),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),

      // ✅ UPDATED DRAWER WITH OWNER PHOTO
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blueAccent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildOwnerAvatar(),
                  const SizedBox(height: 10),
                  Text(
                    "Hello, $_ownerName",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _shopName,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()))
                    .then((_) async {
                  // ✅ refresh after profile update
                  await _loadOwnerProfile();
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Manage Items'),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ManageItemsScreen())),
            ),
            const Divider(),

            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),

            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Analytics'),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ShopAnalyticsScreen())),
            ),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title:
                  const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: _forceLogout,
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
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text("Welcome Back!",
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text("Here is what's happening in your shop today."),
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
                    icon: Icons.list_alt,
                    label: "View Orders",
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ShopOwnerOrdersScreen()),
                    ),
                  ),
                  _buildDashboardCard(
                    icon: Icons.inventory_2_outlined,
                    label: "Add Items",
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddItemsScreen()),
                    ),
                  ),
                  _buildDashboardCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: "Wallet",
                    color: Colors.purple,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ShopOwnerWalletScreen()),
                    ),
                  ),
                  _buildDashboardCard(
                    icon: Icons.menu_book,
                    label: "Khata Book",
                    color: Colors.teal,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ShopKhataListScreen()),
                    ),
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

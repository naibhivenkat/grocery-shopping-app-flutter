import 'package:flutter/material.dart';
import 'package:grocery_app_new_flutter/screens/shop_items_screen.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../models/shop_model.dart';


class ShopSelectionScreen extends StatefulWidget {
  const ShopSelectionScreen({super.key});

  @override
  State<ShopSelectionScreen> createState() => _ShopSelectionScreenState();
}

class _ShopSelectionScreenState extends State<ShopSelectionScreen> {
  List<Shop> _shops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    // Check if customer ID exists (security check)
    String? customerId = await SessionManager.getCustomerId();
    if (customerId == null) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: No Customer ID found")));
         Navigator.pop(context); // Go back
      }
      return;
    }

    // Fetch from API
    List<Shop> shops = await ApiService.getAllShops();
    
    if (mounted) {
      setState(() {
        _shops = shops;
        _isLoading = false;
      });
    }
  }

  void _onShopSelected(Shop shop) {
    // Show Confirmation Dialog (Matches your Kotlin AlertBuilder)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Shop"),
        content: Text("Do you want to continue with '${shop.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              // Save Selected Shop to Session
              await SessionManager.setShopId(shop.id);
              await SessionManager.setShopInfo(shop.id, shop.name);

              // Navigate to Shop Items (We will build this next!)
              if (mounted) {
       Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ShopItemsScreen(),
          // Pass settings arguments manually
          settings: RouteSettings(
            arguments: {'shopId': shop.id, 'shopName': shop.name},
          ),
        ),
      );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Shop"),
        backgroundColor: Colors.green,
        actions: [
          // Cart Button
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {
              // We haven't built the Cart Logic yet
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Cart feature coming soon!"))
              );
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shops.isEmpty
              ? const Center(child: Text("No shops available"))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _shops.length,
                  itemBuilder: (context, index) {
                    final shop = _shops[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 3,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.store, color: Colors.white),
                        ),
                        title: Text(shop.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(shop.address),
                        onTap: () => _onShopSelected(shop),
                      ),
                    );
                  },
                ),
    );
  }
}
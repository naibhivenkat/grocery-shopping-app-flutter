import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import 'add_items_screen.dart';
import 'update_item_screen.dart';

class ManageItemsScreen extends StatefulWidget {
  const ManageItemsScreen({super.key});

  @override
  State<ManageItemsScreen> createState() => _ManageItemsScreenState();
}

class _ManageItemsScreenState extends State<ManageItemsScreen> {
  List<dynamic> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    final shopId = await SessionManager.getShopId();
    
    if (shopId != null) {
      final items = await ApiService.getShopItems(shopId);
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } else {
      if(mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Shop ID not found")));
    }
  }

  void _navigateToUpdate(Map<String, dynamic> item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UpdateItemScreen(item: item)),
    );
    _fetchItems();
  }

  Widget _buildImageWidget(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(Icons.image, color: Colors.grey);
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl, 
        fit: BoxFit.cover, 
        errorBuilder: (_,__,___) => const Icon(Icons.broken_image, color: Colors.red)
      );
    } 
    
    // Clean Path logic
    String assetPath = imageUrl.trim();
    if (assetPath.startsWith('/')) assetPath = assetPath.substring(1);
    if (!assetPath.startsWith('assets/')) assetPath = 'assets/$assetPath';

    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.broken_image, color: Colors.red);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Items"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchItems)
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
           await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddItemsScreen()));
           _fetchItems();
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : RefreshIndicator(
            onRefresh: _fetchItems,
            child: ListView.separated(
              key: UniqueKey(),
              padding: const EdgeInsets.all(10),
              itemCount: _items.length,
              separatorBuilder: (ctx, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return _buildItemCard(_items[index]);
              },
            ),
          ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    String name = item['name'] ?? "Unknown";
    double price = double.tryParse(item['price']?.toString() ?? "0") ?? 0.0;
    int stock = double.tryParse(item['stockQuantity']?.toString() ?? "0")?.toInt() ?? 0;
    
    // ✅ FIX: Check BOTH keys ('image' from seed, 'imageUrl' from app)
    String? imageUrl = item['image'] ?? item['imageUrl'];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      leading: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300)
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildImageWidget(imageUrl),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("Stock: $stock"),
      trailing: Text(
        "₹${price.toStringAsFixed(2)}", 
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
      ),
      onLongPress: () => _navigateToUpdate(item),
      onTap: () => _navigateToUpdate(item),
    );
  }
}
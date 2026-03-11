import 'package:flutter/material.dart';
import '../models/item_model.dart';
import '../services/api_service.dart';
import '../services/cart_manager.dart';
import 'cart_screen.dart'; 

class ShopItemsScreen extends StatefulWidget {
  const ShopItemsScreen({super.key});

  @override
  State<ShopItemsScreen> createState() => _ShopItemsScreenState();
}

class _ShopItemsScreenState extends State<ShopItemsScreen> {
  List<Item> _items = [];
  bool _isLoading = true;
  String? shopId;
  String? shopName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Retrieve arguments passed from ShopSelectionScreen
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      shopId = args['shopId'];
      shopName = args['shopName'];
      _loadItems();
    }
  }

  Future<void> _loadItems() async {
    if (shopId == null) return;
    List<Item> items = await ApiService.getItems(shopId!);
    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
  }

  // --- 🖼️ IMAGE HELPER ---
  Widget _buildItemImage(String? url) {
    if (url == null || url.isEmpty) {
      return const Icon(Icons.image, color: Colors.grey);
    }

    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
      );
    }

    // Local asset
    return Image.asset(
      "assets/$url", 
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.broken_image, color: Colors.red);
      },
    );
  }

  // Logic to show the Quantity Dialog
  void _showAddToCartDialog(Item item) {
    final TextEditingController qtyController = TextEditingController();
    

    String selectedUnit = "KG"; 

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Add ${item.name}"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: qtyController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: "Quantity"),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedUnit,
                    isExpanded: true,
                    // The list values MUST match the default 'selectedUnit' exactly
                    items: ["KG", "Grams"].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setDialogState(() {
                          selectedUnit = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    double? qty = double.tryParse(qtyController.text);
                    if (qty == null || qty <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Quantity")));
                      return;
                    }
                    
                    // Add to Singleton Cart Manager
                    CartManager().addToCart(item, shopId!, qty, selectedUnit);
                    
                    Navigator.pop(context); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("${item.name} added to cart!"))
                    );
                  },
                  child: const Text("Add"),
                )
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(shopName ?? "Shop Items"),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text("No items found in this shop."))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[200],
                              child: _buildItemImage(item.imageUrl), 
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text("₹${item.price.toStringAsFixed(2)}", style: const TextStyle(color: Colors.green, fontSize: 16)),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _showAddToCartDialog(item),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text("ADD", style: TextStyle(color: Colors.white)),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
      // ✅ CONNECTED TO CART SCREEN
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
           if (shopId != null) {
             Navigator.push(
               context, 
               MaterialPageRoute(
                 builder: (_) => CartScreen(shopId: shopId!, shopName: shopName ?? "Shop")
               )
             );
           }
        },
        label: const Text("Go to Cart"),
        icon: const Icon(Icons.shopping_cart),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../services/session_manager.dart';
import '../services/api_service.dart';
import 'shop_owner_dashboard.dart'; 

class AddItemsScreen extends StatefulWidget {
  const AddItemsScreen({super.key});

  @override
  State<AddItemsScreen> createState() => _AddItemsScreenState();
}

class _AddItemsScreenState extends State<AddItemsScreen> {
  Map<String, dynamic>? _groceryData;
  List<dynamic> _categories = [];
  List<dynamic> _currentItems = [];
  
  String? _selectedCategory;
  Map<String, dynamic>? _selectedItem;
  
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  final List<Map<String, dynamic>> _itemsToSend = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadJsonData();
  }

  Future<void> _loadJsonData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/grocery_items.json');
      final data = jsonDecode(jsonString);
      setState(() {
        _groceryData = data;
        _categories = data['categories'];
        if (_categories.isNotEmpty) {
          _setCategory(_categories[0]['name']);
        }
      });
    } catch (e) {
      print("Error loading JSON: $e");
    }
  }

  void _setCategory(String categoryName) {
    final category = _categories.firstWhere((c) => c['name'] == categoryName);
    setState(() {
      _selectedCategory = categoryName;
      _currentItems = category['items'];
      _selectedItem = null;
      _descriptionController.clear();
      _priceController.clear();
    });
  }

  void _setItem(Map<String, dynamic> item) {
    setState(() {
      _selectedItem = item;
      _descriptionController.text = item['description'] ?? "";
    });
  }

  // ✅ Helper to clean paths (Handles leading / and missing assets/)
  String _getCleanPath(String path) {
    if (path.startsWith('http')) return path;
    String clean = path;
    if (clean.startsWith('/')) clean = clean.substring(1); 
    if (!clean.startsWith('assets/')) clean = 'assets/$clean';
    return clean;
  }

  void _addItemToList() {
    if (_selectedItem == null || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select item and enter price")));
      return;
    }

    final price = double.tryParse(_priceController.text) ?? 0.0;
    
    final newItem = {
      "name": _selectedItem!['name'],
      "description": _descriptionController.text,
      "price": price,
      "stockQuantity": 100.0,
      "imageUrl": _selectedItem!['image'], // Raw path from JSON
      "category": _selectedCategory
    };

    setState(() {
      _itemsToSend.add(newItem);
      _priceController.clear();
    });
  }

  Future<void> _submitItems() async {
    if (_itemsToSend.isEmpty) return;

    setState(() => _isLoading = true);
    final shopId = await SessionManager.getShopId();

    if (shopId == null) {
      setState(() => _isLoading = false);
      return;
    }

    bool success = await ApiService.addShopItems(shopId, _itemsToSend);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        await SessionManager.setHasItemsAdded(true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Items Added Successfully!")));
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (_) => const ShopOwnerDashboardScreen()), 
          (route) => false
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to add items.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Items"), backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
      body: _groceryData == null 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // INPUT AREA
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Preview Image (Top)
                      if (_selectedItem != null)
                        Container(
                          height: 100,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Image.asset(
                            _getCleanPath(_selectedItem!['image']),
                            errorBuilder: (c,e,s) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          ),
                        ),

                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        items: _categories.map<DropdownMenuItem<String>>((c) => DropdownMenuItem(value: c['name'], child: Text(c['name']))).toList(),
                        onChanged: (val) => _setCategory(val!),
                        decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 10),

                      DropdownButtonFormField<Map<String, dynamic>>(
                        value: _selectedItem,
                        items: _currentItems.map<DropdownMenuItem<Map<String, dynamic>>>((item) => DropdownMenuItem(value: item, child: Text(item['name']))).toList(),
                        onChanged: (val) => _setItem(val!),
                        decoration: const InputDecoration(labelText: "Item", border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 10),

                      TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price", prefixText: "₹ ", border: OutlineInputBorder())),
                      const SizedBox(height: 20),

                      ElevatedButton.icon(
                        onPressed: _addItemToList,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text("Add to List", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, minimumSize: const Size(double.infinity, 50)),
                      ),
                    ],
                  ),
                ),
              ),

              // BOTTOM CART LIST
              if (_itemsToSend.isNotEmpty)
                Container(
                  color: Colors.grey[100],
                  height: 250,
                  child: Column(
                    children: [
                       Padding(padding: const EdgeInsets.all(8.0), child: Text("Items to Save (${_itemsToSend.length})", style: const TextStyle(fontWeight: FontWeight.bold))),
                       Expanded(
                         child: ListView.separated(
                           padding: const EdgeInsets.symmetric(horizontal: 16),
                           itemCount: _itemsToSend.length,
                           separatorBuilder: (_, __) => const Divider(height: 1),
                           itemBuilder: (ctx, i) {
                             final item = _itemsToSend[i];
                             return ListTile(
                               contentPadding: EdgeInsets.zero,
                               // ✅ SHOW IMAGE IN LIST
                               leading: Container(
                                 width: 40, height: 40,
                                 decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Colors.white),
                                 child: Image.asset(
                                   _getCleanPath(item['imageUrl']),
                                   fit: BoxFit.cover,
                                   errorBuilder: (_,__,___) => const Icon(Icons.broken_image, size: 20),
                                 ),
                               ),
                               title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                               subtitle: Text("Price: ₹${item['price']}"),
                               trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _itemsToSend.removeAt(i))),
                             );
                           },
                         ),
                       ),
                       Padding(
                         padding: const EdgeInsets.all(16.0),
                         child: SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isLoading ? null : _submitItems, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)), child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("FINISH & SAVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                       )
                    ],
                  ),
                )
            ],
          ),
    );
  }
}
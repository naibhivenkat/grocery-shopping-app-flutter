import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UpdateItemScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const UpdateItemScreen({super.key, required this.item});

  @override
  State<UpdateItemScreen> createState() => _UpdateItemScreenState();
}

class _UpdateItemScreenState extends State<UpdateItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _qtyController;
  late TextEditingController _descController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item['name']);
    _priceController = TextEditingController(text: widget.item['price']?.toString());
    _qtyController = TextEditingController(text: widget.item['stockQuantity']?.toString());
    _descController = TextEditingController(text: widget.item['description']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    bool success = await ApiService.updateItem(widget.item['id'], {
      "name": _nameController.text.trim(),
      "price": _priceController.text.trim(),
      "quantity": _qtyController.text.trim(),
      "description": _descController.text.trim(),
    });

    if(mounted) setState(() => _isLoading = false);

    if (success) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item Updated Successfully")));
        Navigator.pop(context); 
      }
    } else {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Update Failed")));
    }
  }

  Future<void> _handleDelete() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Item"),
        content: const Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    bool success = await ApiService.deleteItem(widget.item['id']);
    if(mounted) setState(() => _isLoading = false);

    if (success) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item Deleted")));
        Navigator.pop(context);
      }
    } else {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Delete Failed")));
    }
  }

  // ✅ FIXED: Check both keys here too
  Widget _buildHeaderImage() {
    String? imageUrl = widget.item['image'] ?? widget.item['imageUrl'];
    
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: 200, 
        width: double.infinity,
        color: Colors.grey[200], 
        child: const Center(child: Icon(Icons.image, size: 64, color: Colors.grey))
      );
    }

    ImageProvider imgProvider;
    if (imageUrl.startsWith('http')) {
      imgProvider = NetworkImage(imageUrl);
    } else {
      String assetPath = imageUrl.trim();
      if (assetPath.startsWith('/')) assetPath = assetPath.substring(1);
      if (!assetPath.startsWith('assets/')) assetPath = 'assets/$assetPath';
      imgProvider = AssetImage(assetPath);
    }

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        image: DecorationImage(image: imgProvider, fit: BoxFit.contain),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Item"), backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderImage(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "Item Name", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Price", border: OutlineInputBorder()),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _qtyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Quantity", border: OutlineInputBorder()),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),
                    
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _handleUpdate,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 16)),
                              child: const Text("UPDATE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _handleDelete,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 16)),
                              child: const Text("DELETE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../services/api_service.dart'; // ✅ Use API Service

class ShopOwnerSelectCustomerScreen extends StatefulWidget {
  const ShopOwnerSelectCustomerScreen({super.key});

  @override
  State<ShopOwnerSelectCustomerScreen> createState() => _ShopOwnerSelectCustomerScreenState();
}

class _ShopOwnerSelectCustomerScreenState extends State<ShopOwnerSelectCustomerScreen> {
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  // ✅ UPDATED: Fetch from API (Fixes Permission Denied)
  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    
    // Call the backend API
    final customers = await ApiService.getAllCustomers();

    if (mounted) {
      setState(() {
        _customers = List<Map<String, dynamic>>.from(customers);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Customer"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _customers.isEmpty
              ? const Center(child: Text("No customers found."))
              : ListView.separated(
                  padding: const EdgeInsets.all(10),
                  itemCount: _customers.length,
                  separatorBuilder: (ctx, i) => const Divider(),
                  itemBuilder: (context, index) {
                    final user = _customers[index];
                    return SelectCustomerTile(
                      user: user,
                      onTap: () {
                        // ✅ Return the selected USER object to the previous screen
                        Navigator.pop(context, user);
                      },
                    );
                  },
                ),
    );
  }
}

// -----------------------------------------------------------
// Custom Tile Widget
// -----------------------------------------------------------
class SelectCustomerTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onTap;

  const SelectCustomerTile({super.key, required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    String name = user['fullName'] ?? user['username'] ?? "Unknown";
    String phone = user['phone'] ?? "";

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade100,
        child: Text(name.isNotEmpty ? name[0].toUpperCase() : "?"),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(phone.isNotEmpty ? "Phone: $phone" : "Phone: -"),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    );
  }
}
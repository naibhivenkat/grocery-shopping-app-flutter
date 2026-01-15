import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Placeholder for Detail Screen (You haven't provided this file yet)
class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  const OrderDetailScreen({super.key, required this.order});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Order Details")), body: Text(order.toString()));
}

class ShopOrdersScreen extends StatefulWidget {
  const ShopOrdersScreen({super.key});

  @override
  State<ShopOrdersScreen> createState() => _ShopOrdersScreenState();
}

class _ShopOrdersScreenState extends State<ShopOrdersScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String _shopName = "My Shop";
  final String baseUrl = "http://10.0.2.2:5000";

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final shopId = prefs.getString('shopId');
    _shopName = prefs.getString('shopName') ?? "My Shop";

    if (shopId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/get_shop_orders/$shopId'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        // SORTING LOGIC (Pending -> Packed -> Delivered -> Cancelled)
        data.sort((a, b) {
           return _statusPriority(a['status']).compareTo(_statusPriority(b['status']));
        });

        setState(() {
          _orders = data;
        });
      }
    } catch (e) {
      print("Error fetching orders: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  int _statusPriority(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending': return 0;
      case 'packed': return 1;
      case 'delivered': return 2;
      case 'cancelled': return 3;
      default: return 4;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'packed': return Colors.blue;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Orders: $_shopName"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchOrders)
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _orders.isEmpty 
           ? const Center(child: Text("No orders found."))
           : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _orders.length,
              itemBuilder: (ctx, i) {
                final order = _orders[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(order['status']).withOpacity(0.2),
                      child: Icon(Icons.shopping_bag, color: _getStatusColor(order['status'])),
                    ),
                    title: Text("Order #${order['id'].toString().substring(0, 5)}..."),
                    subtitle: Text("Total: ₹${order['total_amount']} • Items: ${(order['items'] as List).length}"),
                    trailing: Chip(
                      label: Text(order['status'] ?? "Unknown", style: const TextStyle(color: Colors.white, fontSize: 12)),
                      backgroundColor: _getStatusColor(order['status']),
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)));
                    },
                  ),
                );
              },
           ),
    );
  }
}
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import 'order_detail_screen.dart';

class ShopOwnerOrdersScreen extends StatefulWidget {
  const ShopOwnerOrdersScreen({super.key});

  @override
  State<ShopOwnerOrdersScreen> createState() => _ShopOwnerOrdersScreenState();
}

class _ShopOwnerOrdersScreenState extends State<ShopOwnerOrdersScreen> {
  List<dynamic> _allOrders = []; // Stores everything from API
  List<dynamic> _displayedOrders = []; // Stores what is currently visible
  bool _isLoading = true;
  String _shopName = "My Shop";
  
  // "Active" = Pending, Packed, Confirmed
  // "History" = Delivered, Cancelled
  String _selectedFilter = "Active"; 

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);

    String? shopId = await SessionManager.getShopId();
    String? shopName = await SessionManager.getShopName();

    if (shopId == null) {
      if(mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No Shop Assigned")));
      }
      return;
    }

    List<dynamic> orders = await ApiService.getShopOrders(shopId);

    // ✅ SORTING: Time Based (Newest First)
    orders.sort((a, b) {
      DateTime dateA = DateTime.tryParse(a['created_at'] ?? "") ?? DateTime(2000);
      DateTime dateB = DateTime.tryParse(b['created_at'] ?? "") ?? DateTime(2000);
      return dateB.compareTo(dateA); // Descending (Newest first)
    });

    if (mounted) {
      setState(() {
        _allOrders = orders;
        _shopName = shopName ?? "My Shop";
        _applyFilter(); // Apply default filter immediately
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == "Active") {
        // ✅ Show everything EXCEPT Delivered & Cancelled
        _displayedOrders = _allOrders.where((o) {
          String status = (o['status'] ?? "").toString().toLowerCase();
          return status != "delivered" && status != "cancelled";
        }).toList();
      } else {
        // ✅ Show ONLY Delivered & Cancelled
        _displayedOrders = _allOrders.where((o) {
          String status = (o['status'] ?? "").toString().toLowerCase();
          return status == "delivered" || status == "cancelled";
        }).toList();
      }
    });
  }

  void _navigateToDetails(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          orderId: order['order_uuid'],
          preloadedOrder: order,
        ),
      ),
    ).then((_) {
      _fetchOrders(); // Refresh list on return
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending": return Colors.orange;
      case "packed": return Colors.blue;
      case "delivered": return Colors.green;
      case "cancelled": return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Orders: $_shopName"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchOrders)
        ],
      ),
      body: Column(
        children: [
          // 🔹 FILTER CHIPS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.grey[100],
            child: Row(
              children: [
                _buildFilterChip("Active", Icons.local_shipping),
                const SizedBox(width: 10),
                _buildFilterChip("History", Icons.history),
              ],
            ),
          ),

          // 🔹 ORDER LIST
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _displayedOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            Text("No $_selectedFilter Orders", style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: _displayedOrders.length,
                        itemBuilder: (context, index) {
                          final order = _displayedOrders[index];
                          final customer = order['customer'];
                          final items = order['items'] as List;
                          final status = order['status'] ?? "Unknown";
                          
                          double totalAmount = double.tryParse(order['total']?.toString() ?? "0") ?? 0.0;
                          // Fallback calc if total is missing
                          if(totalAmount == 0.0) {
                             totalAmount = items.fold(0.0, (sum, item) => sum + (double.parse(item['price'].toString()) * double.parse(item['quantity'].toString())));
                          }

                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              side: status.toLowerCase() == 'cancelled' 
                                ? const BorderSide(color: Colors.red, width: 1) 
                                : BorderSide.none,
                              borderRadius: BorderRadius.circular(10)
                            ),
                            color: status.toLowerCase() == 'cancelled' ? Colors.red.shade50 : Colors.white,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => _navigateToDetails(order),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "🧑 ${customer != null ? (customer['fullName'] ?? customer['username']) : 'Unknown'}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 5),
                                    Text("🧾 UUID: ...${order['order_uuid'].toString().substring(0, 8)}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 10),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("📦 Items: ${items.length}"),
                                        Text("💰 ₹${totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _getStatusColor(status),
                                          padding: const EdgeInsets.symmetric(vertical: 10)
                                        ),
                                        onPressed: () => _navigateToDetails(order),
                                        child: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    bool isSelected = _selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = label;
            _applyFilter();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? Colors.blueAccent : Colors.grey.shade300),
            boxShadow: isSelected ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 5)] : []
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
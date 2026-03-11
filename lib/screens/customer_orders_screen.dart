import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../models/shop_model.dart';
import 'order_detail_screen.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen>
    with SingleTickerProviderStateMixin {
  // Data
  List<dynamic> _allOrders = [];
  List<dynamic> _filteredOrders = [];
  Map<String, String> _shopMap = {}; // ShopID -> ShopName

  // UI State
  bool _isLoading = true;

  // ✅ Only for History tab filter
  String _selectedHistoryFilter = "All";
  final List<String> _historyFilterOptions = ["All", "Delivered", "Cancelled"];

  // ✅ Tabs
  late TabController _tabController;
  int _currentTabIndex = 0; // 0 = Active, 1 = History

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _currentTabIndex = _tabController.index;
        _filterOrders(); // ✅ apply filter on tab switch
      });
    });

    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    final customerId = await SessionManager.getCustomerId();
    if (customerId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1) Fetch Shops
      List<Shop> shops = await ApiService.getAllShops();
      _shopMap = {for (var s in shops) s.id: s.name};

      // 2) Fetch Orders
      List<dynamic> orders = await ApiService.getCustomerOrders(customerId);

      if (mounted) {
        setState(() {
          _allOrders = orders;
          _filterOrders();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ Parse date safely for sorting
  DateTime _getOrderDate(dynamic order) {
    try {
      final createdAt = order["created_at"];
      if (createdAt == null) return DateTime.fromMillisecondsSinceEpoch(0);

      // if backend sends ISO string
      if (createdAt is String) {
        return DateTime.tryParse(createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
      }

      return DateTime.fromMillisecondsSinceEpoch(0);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  // ✅ Filter + Sort (latest first)
  void _filterOrders() {
    List<dynamic> workingList = List.from(_allOrders);

    // ✅ 1) Split by Tabs
    workingList = workingList.where((order) {
      String status = (order['status'] ?? "").toString().toLowerCase();

      if (_currentTabIndex == 0) {
        // ✅ Active Orders
        return status == "pending" || status == "confirmed" || status == "paid" || status == "packed";

      } else {
        // ✅ History Orders
        return status == "delivered" || status == "cancelled";
      }
    }).toList();

    // ✅ 2) History dropdown filter ONLY
    if (_currentTabIndex == 1 && _selectedHistoryFilter != "All") {
      workingList = workingList.where((order) {
        String status = (order['status'] ?? "").toString().toLowerCase();
        return status == _selectedHistoryFilter.toLowerCase();
      }).toList();
    }

    // ✅ 3) Sort by latest first
    workingList.sort((a, b) => _getOrderDate(b).compareTo(_getOrderDate(a)));

    setState(() {
      _filteredOrders = workingList;
    });
  }

  // --- Helper: Status Colors ---
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;
      case "packed":
        return Colors.blue;
      case "delivered":
        return Colors.green;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Active Orders"),
            Tab(text: "History"),
          ],
        ),
      ),
      body: Column(
        children: [
          // ✅ Show FILTER only on History tab
          if (_currentTabIndex == 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[200],
              child: Row(
                children: [
                  const Text(
                    "Filter: ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedHistoryFilter,
                          isExpanded: true,
                          items: _historyFilterOptions.map((value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedHistoryFilter = newValue;
                                _filterOrders();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ✅ ORDER LIST
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
                    ? const Center(child: Text("No orders found."))
                    : RefreshIndicator(
                        onRefresh: _fetchData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: _filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = _filteredOrders[index];
                            final shopId = order['shopId'] ?? "";
                            final shopName = _shopMap[shopId] ?? "Unknown Shop";
                            final status = order['status'] ?? "Unknown";
                            final items = order['items'] as List;

                            // ✅ Total calculation
                            double totalAmount =
                                double.tryParse(order['total']?.toString() ?? "0") ?? 0.0;

                            if (totalAmount == 0 && items.isNotEmpty) {
                              totalAmount = items.fold(
                                0.0,
                                (sum, item) =>
                                    sum +
                                    (double.parse(item['price'].toString()) *
                                        double.parse(item['quantity'].toString())),
                              );
                            }

                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: status.toLowerCase() == 'cancelled'
                                    ? const BorderSide(color: Colors.red)
                                    : BorderSide.none,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OrderDetailScreen(
                                        orderId: order['order_uuid'],
                                        preloadedOrder: order,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "🏪 Shop: $shopName",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 5),

                                      Text(
                                        "🧾 Order #: ${order['order_uuid'] ?? 'N/A'}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 10),

                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text("📦 Items: ${items.length}"),
                                          Text(
                                            "💰 ₹${totalAmount.toStringAsFixed(2)}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import '../services/api_service.dart';
// import '../services/session_manager.dart';
// import 'shop_owner_select_customer_screen.dart';
// import 'shop_khata_detail_screen.dart'; 

// class ShopKhataListScreen extends StatefulWidget {
//   const ShopKhataListScreen({super.key});

//   @override
//   State<ShopKhataListScreen> createState() => _ShopKhataListScreenState();
// }

// class _ShopKhataListScreenState extends State<ShopKhataListScreen> {
//   List<dynamic> _allAccounts = [];
//   List<dynamic> _filteredAccounts = [];
//   bool _isLoading = true;
//   String _selectedFilter = "All"; 

//   @override
//   void initState() {
//     super.initState();
//     _loadAccounts();
//   }

//   Future<void> _loadAccounts() async {
//     setState(() => _isLoading = true);
//     final shopId = await SessionManager.getShopId();
//     if (shopId != null) {
//       final data = await ApiService.getKhataCustomers(shopId);
//       if (mounted) {
//         setState(() {
//           _allAccounts = data;
//           _applyFilter();
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   void _applyFilter() {
//     setState(() {
//       if (_selectedFilter == "All") {
//         _filteredAccounts = List.from(_allAccounts);
//       } else if (_selectedFilter == "Pending") {
//         _filteredAccounts = _allAccounts.where((a) => a['pending_status'] == 'pending').toList();
//       } else if (_selectedFilter == "Approved") {
//         _filteredAccounts = _allAccounts.where((a) => a['pending_status'] == 'approved').toList();
//       } else if (_selectedFilter == "Rejected") {
//         _filteredAccounts = _allAccounts.where((a) => a['pending_status'] == 'rejected').toList();
//       }
//     });
//   }

//   double _calculateTotalDue() {
//     double total = 0.0;
//     for (var acc in _filteredAccounts) {
//       double bal = double.tryParse(acc['balance']?.toString() ?? "0") ?? 0.0;
//       if (bal > 0) total += bal; 
//     }
//     return total;
//   }

//   // ✅ NEW: Handle Khata Creation after selection
//   Future<void> _createKhataForUser(Map<String, dynamic> customer) async {
//     setState(() => _isLoading = true);
//     final shopId = await SessionManager.getShopId();

//     if (shopId == null) return;

//     // Matches Kotlin logic
//     bool success = await ApiService.createKhataLedger({
//       "shop_id": shopId,
//       "customer_id": customer['id'] ?? customer['customerId'],
//       "customer_name": customer['fullName'] ?? customer['username'],
//       "phone": customer['phone'] ?? ""
//     });

//     setState(() => _isLoading = false);

//     if (success) {
//       if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Khata Created Successfully")));
//       _loadAccounts(); // Refresh list
//     } else {
//       if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to create Khata")));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Khata Management"),
//         backgroundColor: Colors.blueAccent,
//         foregroundColor: Colors.white,
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () async {
//           // 1. Open Selection Screen & Wait for result
//           final selectedUser = await Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => const ShopOwnerSelectCustomerScreen()),
//           );

//           // 2. If user selected (Matches onActivityResult in Kotlin)
//           if (selectedUser != null && selectedUser is Map<String, dynamic>) {
//              _createKhataForUser(selectedUser);
//           }
//         },
//         label: const Text("Create Khata"),
//         icon: const Icon(Icons.add),
//         backgroundColor: Colors.blueAccent,
//         foregroundColor: Colors.white,
//       ),
//       body: Column(
//         children: [
//           // SUMMARY
//           Container(
//             padding: const EdgeInsets.all(16),
//             color: Colors.blue.shade50,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 Column(
//                   children: [
//                     const Text("Customers", style: TextStyle(color: Colors.grey)),
//                     Text("${_filteredAccounts.length}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//                   ],
//                 ),
//                 Column(
//                   children: [
//                     const Text("Total Due", style: TextStyle(color: Colors.grey)),
//                     Text("₹${_calculateTotalDue().toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           // FILTERS
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//             child: Row(
//               children: ["All", "Pending", "Approved", "Rejected"].map((filter) {
//                 return Padding(
//                   padding: const EdgeInsets.only(right: 8.0),
//                   child: ChoiceChip(
//                     label: Text(filter),
//                     selected: _selectedFilter == filter,
//                     onSelected: (val) {
//                       setState(() {
//                         _selectedFilter = filter;
//                         _applyFilter();
//                       });
//                     },
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),

//           // LIST
//           Expanded(
//             child: _isLoading 
//               ? const Center(child: CircularProgressIndicator()) 
//               : ListView.builder(
//                   padding: const EdgeInsets.all(12),
//                   itemCount: _filteredAccounts.length,
//                   itemBuilder: (ctx, i) => _buildKhataCard(_filteredAccounts[i]),
//                 ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildKhataCard(Map<String, dynamic> account) {
//     String name = account['customer_name'] ?? account['customerName'] ?? "Unknown";
//     String phone = account['phone'] ?? "N/A";
    
//     double balance = double.tryParse(account['balance']?.toString() ?? "0") ?? 0.0;
//     double absBal = balance.abs();
    
//     String statusText = "CLEAR";
//     Color statusColor = Colors.grey;

//     if (account['pending_status'] == 'pending') {
//       statusText = "PENDING CASH";
//       statusColor = Colors.orange;
//     } else if (account['pending_status'] == 'approved') {
//       statusText = "APPROVED";
//       statusColor = Colors.green;
//     } else if (account['pending_status'] == 'rejected') {
//       statusText = "REJECTED";
//       statusColor = Colors.red;
//     } else if (balance > 0) {
//       statusText = "RECEIVABLE"; 
//       statusColor = Colors.green; 
//     } else if (balance < 0) {
//       statusText = "PAYABLE"; 
//       statusColor = Colors.red;
//     }

//     return Card(
//       elevation: 2,
//       margin: const EdgeInsets.only(bottom: 12),
//       child: ListTile(
//         contentPadding: const EdgeInsets.all(12),
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//               decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(4)),
//               child: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 10)),
//             )
//           ],
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Phone: $phone"),
//             const SizedBox(height: 5),
//             Text(
//               "₹${absBal.toStringAsFixed(2)}", 
//               style: TextStyle(
//                 fontSize: 18, 
//                 fontWeight: FontWeight.bold, 
//                 color: balance != 0 ? Colors.black : Colors.grey
//               )
//             ),
//           ],
//         ),
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => ShopKhataDetailScreen(
//                 customerId: account['customer_id'] ?? account['customerId'] ?? "",
//                 customerName: name,
//               ),
//             ),
//           ).then((_) => _loadAccounts()); 
//         },
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import '../services/api_service.dart';
// import '../services/session_manager.dart';
// import 'shop_owner_select_customer_screen.dart';
// import 'shop_khata_detail_screen.dart'; 

// class ShopKhataListScreen extends StatefulWidget {
//   const ShopKhataListScreen({super.key});

//   @override
//   State<ShopKhataListScreen> createState() => _ShopKhataListScreenState();
// }

// class _ShopKhataListScreenState extends State<ShopKhataListScreen> {
//   List<dynamic> _allAccounts = [];
//   List<dynamic> _filteredAccounts = [];
//   bool _isLoading = true;
//   String _selectedFilter = "All"; 

//   @override
//   void initState() {
//     super.initState();
//     _loadAccounts();
//   }

//   Future<void> _loadAccounts() async {
//     setState(() => _isLoading = true);
//     final shopId = await SessionManager.getShopId();
//     if (shopId != null) {
//       final data = await ApiService.getKhataCustomers(shopId);
//       if (mounted) {
//         setState(() {
//           _allAccounts = data;
//           _applyFilter();
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   void _applyFilter() {
//     setState(() {
//       if (_selectedFilter == "All") {
//         _filteredAccounts = List.from(_allAccounts);
//       } else if (_selectedFilter == "Pending") {
//         _filteredAccounts = _allAccounts.where((a) => a['pending_status'] == 'pending').toList();
//       } else if (_selectedFilter == "Approved") {
//         _filteredAccounts = _allAccounts.where((a) => a['pending_status'] == 'approved').toList();
//       } else if (_selectedFilter == "Rejected") {
//         _filteredAccounts = _allAccounts.where((a) => a['pending_status'] == 'rejected').toList();
//       }
//     });
//   }

//   double _calculateTotalDue() {
//     double total = 0.0;
//     for (var acc in _filteredAccounts) {
//       double bal = double.tryParse(acc['balance']?.toString() ?? "0") ?? 0.0;
//       if (bal > 0) total += bal; 
//     }
//     return total;
//   }

//   // ✅ FIXED: Prioritize 'customerId' to match the User's login session
//   Future<void> _createKhataForUser(Map<String, dynamic> customer) async {
//     setState(() => _isLoading = true);
//     final shopId = await SessionManager.getShopId();

//     if (shopId == null) return;

//     bool success = await ApiService.createKhataLedger({
//       "shop_id": shopId,
//       // 🔴 WAS: customer['id'] ?? customer['customerId']
//       // 🟢 CHANGE TO:
//       "customer_id": customer['customerId'] ?? customer['id'], 
//       "customer_name": customer['fullName'] ?? customer['username'],
//       "phone": customer['phone'] ?? ""
//     });

//     setState(() => _isLoading = false);

//     if (success) {
//       if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Khata Created Successfully")));
//       _loadAccounts(); 
//     } else {
//       if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to create Khata")));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Khata Management"),
//         backgroundColor: Colors.blueAccent,
//         foregroundColor: Colors.white,
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () async {
//           final selectedUser = await Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => const ShopOwnerSelectCustomerScreen()),
//           );

//           if (selectedUser != null && selectedUser is Map<String, dynamic>) {
//              _createKhataForUser(selectedUser);
//           }
//         },
//         label: const Text("Create Khata"),
//         icon: const Icon(Icons.add),
//         backgroundColor: Colors.blueAccent,
//         foregroundColor: Colors.white,
//       ),
//       body: Column(
//         children: [
//           // SUMMARY
//           Container(
//             padding: const EdgeInsets.all(16),
//             color: Colors.blue.shade50,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 Column(
//                   children: [
//                     const Text("Customers", style: TextStyle(color: Colors.grey)),
//                     Text("${_filteredAccounts.length}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//                   ],
//                 ),
//                 Column(
//                   children: [
//                     const Text("Total Due", style: TextStyle(color: Colors.grey)),
//                     Text("₹${_calculateTotalDue().toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           // FILTERS
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//             child: Row(
//               children: ["All", "Pending", "Approved", "Rejected"].map((filter) {
//                 return Padding(
//                   padding: const EdgeInsets.only(right: 8.0),
//                   child: ChoiceChip(
//                     label: Text(filter),
//                     selected: _selectedFilter == filter,
//                     onSelected: (val) {
//                       setState(() {
//                         _selectedFilter = filter;
//                         _applyFilter();
//                       });
//                     },
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),

//           // LIST
//           Expanded(
//             child: _isLoading 
//               ? const Center(child: CircularProgressIndicator()) 
//               : ListView.builder(
//                   padding: const EdgeInsets.all(12),
//                   itemCount: _filteredAccounts.length,
//                   itemBuilder: (ctx, i) => _buildKhataCard(_filteredAccounts[i]),
//                 ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildKhataCard(Map<String, dynamic> account) {
//     String name = account['customer_name'] ?? account['customerName'] ?? "Unknown";
//     String phone = account['phone'] ?? "N/A";
    
//     double balance = double.tryParse(account['balance']?.toString() ?? "0") ?? 0.0;
//     double absBal = balance.abs();
    
//     String statusText = "CLEAR";
//     Color statusColor = Colors.grey;

//     if (account['pending_status'] == 'pending') {
//       statusText = "PENDING CASH";
//       statusColor = Colors.orange;
//     } else if (account['pending_status'] == 'approved') {
//       statusText = "APPROVED";
//       statusColor = Colors.green;
//     } else if (account['pending_status'] == 'rejected') {
//       statusText = "REJECTED";
//       statusColor = Colors.red;
//     } else if (balance > 0) {
//       statusText = "RECEIVABLE"; 
//       statusColor = Colors.green; 
//     } else if (balance < 0) {
//       statusText = "PAYABLE"; 
//       statusColor = Colors.red;
//     }

//     return Card(
//       elevation: 2,
//       margin: const EdgeInsets.only(bottom: 12),
//       child: ListTile(
//         contentPadding: const EdgeInsets.all(12),
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//               decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(4)),
//               child: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 10)),
//             )
//           ],
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Phone: $phone"),
//             const SizedBox(height: 5),
//             Text(
//               "₹${absBal.toStringAsFixed(2)}", 
//               style: TextStyle(
//                 fontSize: 18, 
//                 fontWeight: FontWeight.bold, 
//                 color: balance != 0 ? Colors.black : Colors.grey
//               )
//             ),
//           ],
//         ),
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => ShopKhataDetailScreen(
//                 customerId: account['customer_id'] ?? account['customerId'] ?? "",
//                 customerName: name,
//               ),
//             ),
//           ).then((_) => _loadAccounts()); 
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import 'shop_owner_select_customer_screen.dart';
import 'shop_khata_detail_screen.dart'; 

class ShopKhataListScreen extends StatefulWidget {
  const ShopKhataListScreen({super.key});

  @override
  State<ShopKhataListScreen> createState() => _ShopKhataListScreenState();
}

class _ShopKhataListScreenState extends State<ShopKhataListScreen> {
  List<dynamic> _allAccounts = [];
  List<dynamic> _filteredAccounts = [];
  bool _isLoading = true;
  String _selectedFilter = "All"; 

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    final shopId = await SessionManager.getShopId();
    if (shopId != null) {
      final data = await ApiService.getKhataCustomers(shopId);
      if (mounted) {
        setState(() {
          _allAccounts = data;
          _applyFilter();
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == "All") {
        _filteredAccounts = List.from(_allAccounts);
      } else if (_selectedFilter == "Pending") {
        _filteredAccounts = _allAccounts.where((a) => a['pending_status'] == 'pending').toList();
      } else if (_selectedFilter == "Approved") {
        _filteredAccounts = _allAccounts.where((a) => a['pending_status'] == 'approved').toList();
      } else if (_selectedFilter == "Rejected") {
        _filteredAccounts = _allAccounts.where((a) => a['pending_status'] == 'rejected').toList();
      }
    });
  }

  double _calculateTotalDue() {
    double total = 0.0;
    for (var acc in _filteredAccounts) {
      double bal = double.tryParse(acc['balance']?.toString() ?? "0") ?? 0.0;
      if (bal > 0) total += bal; 
    }
    return total;
  }

  // ✅ FIXED: Check for existing Khata before creating
  Future<void> _createKhataForUser(Map<String, dynamic> customer) async {
    // 1. Identify the Customer ID
    final String selectedCustomerId = customer['customerId'] ?? customer['id'] ?? "";
    final String customerName = customer['fullName'] ?? customer['username'] ?? "Unknown";

    // 2. Check if Khata already exists in the loaded list
    final existingAccount = _allAccounts.firstWhere(
      (acc) {
        String accCustId = acc['customer_id'] ?? acc['customerId'] ?? "";
        return accCustId == selectedCustomerId;
      },
      orElse: () => null,
    );

    // 3. If Exists -> Open Details Directly
    if (existingAccount != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Khata already exists. Opening details...")),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShopKhataDetailScreen(
            customerId: selectedCustomerId,
            customerName: customerName,
          ),
        ),
      ).then((_) => _loadAccounts()); // Refresh on return
      return; 
    }

    // 4. If Not Exists -> Create New via API
    setState(() => _isLoading = true);
    final shopId = await SessionManager.getShopId();

    if (shopId == null) return;

    bool success = await ApiService.createKhataLedger({
      "shop_id": shopId,
      "customer_id": selectedCustomerId,
      "customer_name": customerName,
      "phone": customer['phone'] ?? ""
    });

    setState(() => _isLoading = false);

    if (success) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Khata Created Successfully")));
      _loadAccounts(); // Refresh to show the new account
    } else {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to create Khata")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Khata Management"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final selectedUser = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ShopOwnerSelectCustomerScreen()),
          );

          if (selectedUser != null && selectedUser is Map<String, dynamic>) {
             _createKhataForUser(selectedUser);
          }
        },
        label: const Text("Create Khata"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // SUMMARY
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text("Customers", style: TextStyle(color: Colors.grey)),
                    Text("${_filteredAccounts.length}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                Column(
                  children: [
                    const Text("Total Due", style: TextStyle(color: Colors.grey)),
                    Text("₹${_calculateTotalDue().toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
                  ],
                ),
              ],
            ),
          ),

          // FILTERS
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: ["All", "Pending", "Approved", "Rejected"].map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (val) {
                      setState(() {
                        _selectedFilter = filter;
                        _applyFilter();
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // LIST
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _filteredAccounts.length,
                  itemBuilder: (ctx, i) => _buildKhataCard(_filteredAccounts[i]),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildKhataCard(Map<String, dynamic> account) {
    String name = account['customer_name'] ?? account['customerName'] ?? "Unknown";
    String phone = account['phone'] ?? "N/A";
    
    double balance = double.tryParse(account['balance']?.toString() ?? "0") ?? 0.0;
    double absBal = balance.abs();
    
    String statusText = "CLEAR";
    Color statusColor = Colors.grey;

    if (account['pending_status'] == 'pending') {
      statusText = "PENDING CASH";
      statusColor = Colors.orange;
    } else if (account['pending_status'] == 'approved') {
      statusText = "APPROVED";
      statusColor = Colors.green;
    } else if (account['pending_status'] == 'rejected') {
      statusText = "REJECTED";
      statusColor = Colors.red;
    } else if (balance > 0) {
      statusText = "RECEIVABLE"; 
      statusColor = Colors.green; 
    } else if (balance < 0) {
      statusText = "PAYABLE"; 
      statusColor = Colors.red;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(4)),
              child: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 10)),
            )
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Phone: $phone"),
            const SizedBox(height: 5),
            Text(
              "₹${absBal.toStringAsFixed(2)}", 
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: balance != 0 ? Colors.black : Colors.grey
              )
            ),
          ],
        ),
        onTap: () {
          // Navigate to Details
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShopKhataDetailScreen(
                customerId: account['customer_id'] ?? account['customerId'] ?? "",
                customerName: name,
              ),
            ),
          ).then((_) => _loadAccounts()); // Refresh on return
        },
      ),
    );
  }
}
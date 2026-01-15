import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';

class ShopOwnerWalletScreen extends StatefulWidget {
  const ShopOwnerWalletScreen({super.key});

  @override
  State<ShopOwnerWalletScreen> createState() => _ShopOwnerWalletScreenState();
}

class _ShopOwnerWalletScreenState extends State<ShopOwnerWalletScreen> {
  double _balance = 0.0;
  List<dynamic> _allTransactions = [];
  List<dynamic> _filteredTransactions = [];
  
  bool _isLoading = true;
  String _selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  Future<void> _fetchWalletData() async {
    setState(() => _isLoading = true);
    
    // ✅ CORRECT: Use Shop ID for Shop Wallet endpoints
    final shopId = await SessionManager.getShopId();
    
    if (shopId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Shop ID not found")));
      }
      return;
    }

    // Parallel Fetching
    final balance = await ApiService.getShopWalletBalance(shopId);
    final transactions = await ApiService.getShopWalletTransactions(shopId);

    if (mounted) {
      setState(() {
        _balance = balance;
        _allTransactions = transactions;
        _applyFilter(); 
        _isLoading = false;
      });
    }
  }

  // ... (rest of the file remains the same: _applyFilter, build, etc.) ...
  // Be sure to include the _applyFilter and build methods from the previous full file
  
  void _applyFilter() {
    setState(() {
      if (_selectedFilter == "All") {
        _filteredTransactions = List.from(_allTransactions);
      } else if (_selectedFilter == "Income") {
        _filteredTransactions = _allTransactions.where((t) {
          String type = (t['type'] ?? "").toString().toLowerCase();
          return type == "deposit" || type == "order income";
        }).toList();
      } else if (_selectedFilter == "Refunds") {
        _filteredTransactions = _allTransactions.where((t) {
          final type = (t['type'] ?? "").toString().toLowerCase();
          return type.contains("refund");
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text("Shop Wallet"), backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
      body: Column(
        children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
            child: Column(children: [
              const Text("Total Balance", style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 8),
              Text("₹${_balance.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _buildFilterChip("All"), const SizedBox(width: 10), _buildFilterChip("Income"), const SizedBox(width: 10), _buildFilterChip("Refunds"),
            ]),
          ),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredTransactions.length,
              itemBuilder: (context, index) => _buildTransactionCard(_filteredTransactions[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) => setState(() { _selectedFilter = label; _applyFilter(); }),
      selectedColor: Colors.blueAccent.shade100,
      labelStyle: TextStyle(color: isSelected ? Colors.blue.shade900 : Colors.black, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    String type = tx['type'] ?? "Unknown";
    String date = "Unknown Date";
    try {
        if(tx['dateTime'] != null) {
           date = DateFormat("dd MMM yyyy, hh:mm a").format(DateTime.parse(tx['dateTime']).toLocal());
        }
    } catch (e) {}

    double amount = double.tryParse(tx['amount']?.toString() ?? "0") ?? 0.0;
    String typeLower = type.toLowerCase();
    Color amountColor = Colors.black;
    IconData icon = Icons.history;
    String prefix = "";
    Color iconBg = Colors.grey.shade200;

    if (typeLower == "deposit" || typeLower == "order income") {
      amountColor = Colors.green; icon = Icons.arrow_downward; prefix = "+"; iconBg = Colors.green.shade50;
    } else if (typeLower.contains("refund")) {
      amountColor = Colors.orange; icon = Icons.undo; prefix = "-"; iconBg = Colors.orange.shade50;
    } else if (typeLower == "payment") {
      amountColor = Colors.red; icon = Icons.arrow_upward; prefix = "-"; iconBg = Colors.red.shade50;
    }

    return Card(
      elevation: 2, margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: iconBg, child: Icon(icon, color: amountColor)),
        title: Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Text("$prefix₹${amount.toStringAsFixed(2)}", style: TextStyle(color: amountColor, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
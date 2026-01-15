import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';

class KhataCustomerDetailScreen extends StatefulWidget {
  final String shopId;
  final String shopName;

  const KhataCustomerDetailScreen({super.key, required this.shopId, required this.shopName});

  @override
  State<KhataCustomerDetailScreen> createState() => _KhataCustomerDetailScreenState();
}

class _KhataCustomerDetailScreenState extends State<KhataCustomerDetailScreen> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  double _currentBalance = 0.0;
  String _lastUpdated = ""; // ✅ Added

  @override
  void initState() {
    super.initState();
    _fetchLedger();
  }

  Future<void> _fetchLedger() async {
    final customerId = await SessionManager.getCustomerId();
    if (customerId == null) return;

    final data = await ApiService.getKhataLedger(widget.shopId, customerId);
    
    if (mounted) {
      setState(() {
        if (data != null) {
          _transactions = data['transactions'] ?? [];
          if (data['account'] != null) {
             _currentBalance = double.tryParse(data['account']['balance'].toString()) ?? 0.0;
          }
          // ✅ Update Timestamp
          _lastUpdated = DateFormat('hh:mm a').format(DateTime.now());
        }
        _isLoading = false;
      });
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "Unknown Date";
    try {
      final millis = int.tryParse(timestamp.toString());
      if (millis != null) {
        final dt = DateTime.fromMillisecondsSinceEpoch(millis);
        return DateFormat("dd MMM yyyy, hh:mm a").format(dt);
      }
      final dt = DateTime.parse(timestamp.toString());
      return DateFormat("dd MMM yyyy, hh:mm a").format(dt);
    } catch (e) {
      return "Invalid Date";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shopName),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // SUMMARY HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.teal.shade50,
            child: Column(
              children: [
                const Text("Current Balance", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 5),
                Text(
                  "₹${_currentBalance.abs().toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 32, 
                    fontWeight: FontWeight.bold,
                    color: _currentBalance > 0 ? Colors.red : Colors.green
                  ),
                ),
                Text(
                  _currentBalance > 0 ? "You have to Pay (Due)" : "Advance Amount",
                  style: TextStyle(
                    color: _currentBalance > 0 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ),

          // ✅ Last Updated Text
          if (_lastUpdated.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Last Updated: $_lastUpdated  (Swipe down to refresh)", 
                style: TextStyle(color: Colors.grey[600], fontSize: 12)
              ),
            ),

          // TRANSACTIONS LIST with REFRESH INDICATOR
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : RefreshIndicator( // ✅ Added RefreshIndicator
                  onRefresh: _fetchLedger,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: _transactions.length,
                    separatorBuilder: (ctx, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tx = _transactions[index];
                      final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
                      
                      String note = tx['note'] ?? "";
                      final type = tx['type'] ?? ""; 
                      if (note.isEmpty) note = type.toString().toUpperCase();

                      final dateStr = _formatDate(tx['created_at']);

                      bool isDebit = type.toString().toLowerCase() == "debit"; 
                      Color color = isDebit ? Colors.red : Colors.green;
                      IconData icon = isDebit ? Icons.shopping_cart : Icons.payment;
                      String prefix = isDebit ? "+" : "-";

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.1),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        title: Text(note, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(dateStr, style: const TextStyle(fontSize: 12)),
                        trailing: Text(
                          "$prefix₹${amount.toStringAsFixed(2)}",
                          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      );
                    },
                  ),
                ),
          )
        ],
      ),
    );
  }
}
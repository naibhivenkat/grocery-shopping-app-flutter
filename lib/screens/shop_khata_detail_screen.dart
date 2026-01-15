import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';

class ShopKhataDetailScreen extends StatefulWidget {
  final String customerId;
  final String customerName;

  const ShopKhataDetailScreen({super.key, required this.customerId, required this.customerName});

  @override
  State<ShopKhataDetailScreen> createState() => _ShopKhataDetailScreenState();
}

class _ShopKhataDetailScreenState extends State<ShopKhataDetailScreen> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  double _currentBalance = 0.0;
  Map<String, dynamic>? _accountDetails;
  String _lastUpdated = ""; // ✅ Added for timestamp

  @override
  void initState() {
    super.initState();
    _fetchLedger();
  }

  Future<void> _fetchLedger() async {
    final shopId = await SessionManager.getShopId();
    if (shopId == null) return;

    final data = await ApiService.getKhataLedger(shopId, widget.customerId);
    
    if (mounted) {
      setState(() {
        if (data != null) {
          _transactions = data['transactions'] ?? [];
          if (data['account'] != null) {
             _accountDetails = data['account'];
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

  Future<void> _handleCashApproval(String action) async {
    setState(() => _isLoading = true);
    final shopId = await SessionManager.getShopId();
    
    bool success;
    if (action == "approve") {
      success = await ApiService.approveCashPayment(shopId!, widget.customerId);
    } else {
      success = await ApiService.rejectCashPayment(shopId!, widget.customerId);
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Cash Payment ${action}d")));
      _fetchLedger();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Action Failed")));
    }
  }

  void _showAddTransactionDialog() {
    TextEditingController amountCtrl = TextEditingController();
    TextEditingController noteCtrl = TextEditingController();
    String type = "debit";

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Add Transaction"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Radio(value: "debit", groupValue: type, onChanged: (v) => setState(() => type = v.toString())),
                      const Text("Give Credit (Debit)"),
                    ],
                  ),
                  Row(
                    children: [
                      Radio(value: "credit", groupValue: type, onChanged: (v) => setState(() => type = v.toString())),
                      const Text("Receive Payment (Credit)"),
                    ],
                  ),
                  TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: "Amount"), keyboardType: TextInputType.number),
                  TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: "Note")),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async {
                    double? amt = double.tryParse(amountCtrl.text);
                    if (amt != null && amt > 0) {
                      Navigator.pop(ctx);
                      _submitTransaction(amt, type, noteCtrl.text);
                    }
                  },
                  child: const Text("Add"),
                )
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _submitTransaction(double amount, String type, String note) async {
    setState(() => _isLoading = true);
    final shopId = await SessionManager.getShopId();
    
    bool success = await ApiService.addKhataTransaction({
      "shop_id": shopId,
      "customer_id": widget.customerId,
      "amount": amount,
      "type": type,
      "note": note
    });

    if (success) {
      _fetchLedger();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to add transaction")));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isPending = _accountDetails?['pending_status'] == 'pending';
    double pendingAmount = double.tryParse(_accountDetails?['pending_cash']?.toString() ?? "0") ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: Text(widget.customerName), backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.blue.shade50,
            width: double.infinity,
            child: Column(
              children: [
                Text("₹${_currentBalance.abs().toStringAsFixed(2)}", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _currentBalance > 0 ? Colors.green : Colors.red)),
                Text(_currentBalance > 0 ? "Receivable (You get)" : "Payable (You owe)", style: const TextStyle(fontWeight: FontWeight.bold)),
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

          // PENDING APPROVAL
          if (isPending)
            Card(
              margin: const EdgeInsets.all(16),
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text("Cash Payment Request: ₹$pendingAmount", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(onPressed: () => _handleCashApproval("reject"), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("Reject", style: TextStyle(color: Colors.white))),
                        ElevatedButton(onPressed: () => _handleCashApproval("approve"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text("Approve", style: TextStyle(color: Colors.white))),
                      ],
                    )
                  ],
                ),
              ),
            ),

          // LIST with REFRESH INDICATOR
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : RefreshIndicator( // ✅ Added RefreshIndicator
                  onRefresh: _fetchLedger,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 80), // Space for FAB
                    itemCount: _transactions.length,
                    separatorBuilder: (ctx, i) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final tx = _transactions[i];
                      final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
                      
                      String note = tx['note'] ?? "";
                      final type = tx['type'] ?? ""; 
                      if (note.isEmpty) note = type.toString().toUpperCase();

                      final dateStr = _formatDate(tx['created_at']);

                      bool isDebit = type.toString().toLowerCase() == "debit"; 
                      Color color = isDebit ? Colors.red : Colors.green;
                      IconData icon = isDebit ? Icons.arrow_outward : Icons.arrow_downward;
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
          ),
        ],
      ),
    );
  }
}
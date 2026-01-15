import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // ✅ Add intl package to pubspec.yaml for date formatting
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../models/wallet_transaction_model.dart'; // ✅ Import Model

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _balance = 0.0;
  List<WalletTransaction> _transactions = [];
  List<WalletTransaction> _filteredList = [];
  
  bool _isLoading = true;
  String _selectedFilter = "All";
  String? _userId;

  late Razorpay _razorpay;
  String? _pendingBackendOrderId;

  @override
  void initState() {
    super.initState();
    _initRazorpay();
    _fetchData();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    
    String? role = await SessionManager.getRole();
    if (role == 'customer') {
      _userId = await SessionManager.getCustomerId();
    } else {
      _userId = await SessionManager.getShopkeeperId();
    }

    if (_userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    double bal = await ApiService.getWalletBalance(_userId!);
    List<WalletTransaction> txs = await ApiService.getWalletTransactions(_userId!);

    if (mounted) {
      setState(() {
        _balance = bal;
        _transactions = txs;
        _filterTransactions();
        _isLoading = false;
      });
    }
  }

  void _filterTransactions() {
    setState(() {
      if (_selectedFilter == "All") {
        _filteredList = List.from(_transactions);
      } else if (_selectedFilter == "Credit") {
        _filteredList = _transactions.where((t) => t.type.toLowerCase() == 'deposit').toList();
      } else if (_selectedFilter == "Debit") {
        _filteredList = _transactions.where((t) => t.type.toLowerCase() == 'payment').toList();
      } else if (_selectedFilter == "Refund") {
        _filteredList = _transactions.where((t) => t.type.toLowerCase().contains('refund')).toList();
      }
    });
  }

  // --- ADD MONEY LOGIC ---
  void _openAddMoneyDialog() {
    TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Money"),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Amount (₹)", prefixIcon: Icon(Icons.currency_rupee)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              double? amt = double.tryParse(amountController.text);
              if (amt != null && amt > 0) {
                _createBackendOrder(amt);
              }
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  Future<void> _createBackendOrder(double amount) async {
    setState(() => _isLoading = true);
    final response = await ApiService.createWalletOrder(_userId!, amount);
    if (response != null) {
      _pendingBackendOrderId = response['backend_order_id'];
      String razorpayOrderId = response['razorpay_order_id'];
      _startRazorpay(amount, razorpayOrderId);
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to create order")));
    }
  }

  Future<void> _startRazorpay(double amount, String rzpOrderId) async {
    final prefs = await SharedPreferences.getInstance();
    String phone = prefs.getString('phone') ?? "9999999999";
    String email = "user@grocery.com";

    var options = {
      'key': 'rzp_test_RKK3DuGSaxK9fR', // ✅ REAL KEY
      'amount': (amount * 100).toInt(),
      'name': 'Wallet Recharge',
      'order_id': rzpOrderId,
      'prefill': {'contact': phone, 'email': email}
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print("Razorpay Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_pendingBackendOrderId == null) return;
    bool success = await ApiService.verifyWalletPayment({
      "backend_order_id": _pendingBackendOrderId,
      "payment_id": response.paymentId,
      "order_id": response.orderId,
      "signature": response.signature
    });
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wallet Updated Successfully!")));
      _fetchData();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Verification Failed")));
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payment Failed: ${response.message}")));
  }

  // --- HELPER: FORMAT DATE ---
  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return "Unknown Date";
    try {
      // Assuming Backend sends UTC or standard string
      DateTime dt = DateTime.parse(dateStr).toLocal();
      return DateFormat("dd MMM yyyy, hh:mm a").format(dt);
    } catch (e) {
      return dateStr; // Return raw string if parse fails
    }
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Wallet"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Balance Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))
            ),
            child: Column(
              children: [
                const Text("Current Balance", style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 8),
                Text("₹${_balance.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Add Money"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.purple),
                  onPressed: _openAddMoneyDialog,
                )
              ],
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ["All", "Credit", "Debit", "Refund"].map((filter) {
                bool isSelected = _selectedFilter == filter;
                return ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  selectedColor: Colors.purple.shade100,
                  onSelected: (val) {
                    setState(() {
                      _selectedFilter = filter;
                      _filterTransactions();
                    });
                  },
                );
              }).toList(),
            ),
          ),

          // Transactions List
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _filteredList.isEmpty 
                  ? const Center(child: Text("No transactions found"))
                  : ListView.builder(
                      itemCount: _filteredList.length,
                      itemBuilder: (context, index) {
                        final tx = _filteredList[index];
                        return _buildTransactionItem(tx);
                      },
                    ),
          )
        ],
      ),
    );
  }

  Widget _buildTransactionItem(WalletTransaction tx) {
    Color color = Colors.black;
    IconData icon = Icons.history;
    String prefix = "";

    if (tx.type.toLowerCase() == "deposit") {
      color = Colors.green;
      icon = Icons.arrow_downward;
      prefix = "+";
    } else if (tx.type.toLowerCase() == "payment") {
      color = Colors.red;
      icon = Icons.arrow_upward;
      prefix = "-";
    } else if (tx.type.toLowerCase().contains("refund")) {
      color = Colors.orange;
      icon = Icons.undo;
      prefix = "+";
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(tx.type, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(_formatDate(tx.date)),
      trailing: Text(
        "$prefix₹${tx.amount.toStringAsFixed(2)}",
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      onTap: () {
        // ✅ Show Full Details in Bottom Sheet
        showModalBottomSheet(
          context: context, 
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))
          ),
          builder: (_) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Transaction Details", style: Theme.of(context).textTheme.headlineSmall),
                const Divider(),
                const SizedBox(height: 10),
                _detailRow("Type", tx.type),
                _detailRow("Amount", "₹${tx.amount.toStringAsFixed(2)}", color: color),
                _detailRow("Date", _formatDate(tx.date)),
                _detailRow("Order ID", tx.orderId ?? "N/A"),
              ],
            ),
          )
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? Colors.black)),
        ],
      ),
    );
  }
}
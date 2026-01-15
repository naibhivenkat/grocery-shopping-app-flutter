import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import 'khata_customer_detail_screen.dart'; 

class CustomerKhataScreen extends StatefulWidget {
  const CustomerKhataScreen({super.key});

  @override
  State<CustomerKhataScreen> createState() => _CustomerKhataScreenState();
}

class _CustomerKhataScreenState extends State<CustomerKhataScreen> {
  List<dynamic> _accounts = [];
  bool _isLoading = true;
  String _lastUpdated = "";
  
  // Razorpay Vars
  late Razorpay _razorpay;
  String? _pendingBackendOrderId;
  double _pendingAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _initRazorpay();
    _fetchAccounts();
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

  // ✅ HANDLER 1: Success
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_pendingBackendOrderId == null) return;

    bool success = await ApiService.verifyKhataRazorpayPayment({
      "backend_order_id": _pendingBackendOrderId,
      "payment_id": response.paymentId,
      "order_id": response.orderId,
      "signature": response.signature
    });

    if (success) {
      _fetchAccounts(); // Refresh list to show new balance
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Paid ₹$_pendingAmount successfully!"), backgroundColor: Colors.green)
        );
      }
    } else {
      _showErrorDialog("Payment verification failed");
    }
  }

  // ✅ HANDLER 2: Error
  void _handlePaymentError(PaymentFailureResponse response) {
    _showErrorDialog("Payment Failed: ${response.message}");
  }

  Future<void> _fetchAccounts() async {
    setState(() => _isLoading = true);
    final customerId = await SessionManager.getCustomerId();
    if (customerId != null) {
      final data = await ApiService.getMyKhataAccounts(customerId);
      if (mounted) {
        setState(() {
          _accounts = data;
          _isLoading = false;
          _lastUpdated = DateFormat('hh:mm a').format(DateTime.now());
        });
      }
    }
  }

  // --- NAVIGATION ---
  void _openDetailScreen(Map<String, dynamic> account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KhataCustomerDetailScreen(
          shopId: account['shop_id'] ?? "",
          shopName: account['shop_name'] ?? "Unknown Shop",
        ),
      ),
    );
  }

  // --- PAYMENT UI LOGIC ---
  void _showPaymentOptions(Map<String, dynamic> account) {
    if (account['pending_status'] == 'pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cash payment request pending approval"))
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.account_balance_wallet, color: Colors.purple),
            title: const Text("Wallet"),
            onTap: () {
              Navigator.pop(ctx);
              _handleWalletPayment(account);
            },
          ),
          ListTile(
            leading: const Icon(Icons.money, color: Colors.green),
            title: const Text("Cash Payment"),
            onTap: () {
              Navigator.pop(ctx);
              _showAmountDialog(account, "CASH");
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code, color: Colors.blue),
            title: const Text("UPI / Razorpay"),
            onTap: () {
              Navigator.pop(ctx);
              _showAmountDialog(account, "RAZORPAY");
            },
          ),
        ],
      ),
    );
  }

  void _showAmountDialog(Map<String, dynamic> account, String type) {
    TextEditingController amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type == "CASH" ? "Cash Payment" : "UPI Payment"),
        content: TextField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Enter Amount"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              double? amount = double.tryParse(amountCtrl.text);
              if (amount != null && amount > 0) {
                if (type == "CASH") {
                  _createCashRequest(account, amount);
                } else {
                  _startRazorpayFlow(account, amount);
                }
              }
            },
            child: const Text("Pay"),
          )
        ],
      ),
    );
  }

  // --- PAYMENT METHODS ---

  Future<void> _handleWalletPayment(Map<String, dynamic> account) async {
    final customerId = await SessionManager.getCustomerId();
    if (customerId == null) return;

    double balance = await ApiService.getWalletBalance(customerId);
    if (!mounted) return;

    if (balance <= 0) {
      _showErrorDialog("Wallet Balance is 0. Please add money.");
      return;
    }

    TextEditingController amountCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Pay from Wallet"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Wallet Balance: ₹$balance"),
            const SizedBox(height: 10),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Enter Amount"),
            )
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              double? amt = double.tryParse(amountCtrl.text);
              if (amt != null && amt > 0 && amt <= balance) {
                Navigator.pop(ctx);
                _processWalletPay(account, amt);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Amount")));
              }
            },
            child: const Text("Pay"),
          )
        ],
      ),
    );
  }

  Future<void> _processWalletPay(Map<String, dynamic> account, double amount) async {
    final customerId = await SessionManager.getCustomerId();
    final result = await ApiService.payKhataWallet(customerId!, account['shop_id'], amount);
    if (result['success'] == true) {
      _fetchAccounts();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Paid ₹$amount from Wallet"), backgroundColor: Colors.green));
    } else {
      _showErrorDialog(result['message']);
    }
  }

  Future<void> _createCashRequest(Map<String, dynamic> account, double amount) async {
    final customerId = await SessionManager.getCustomerId();
    final result = await ApiService.createCashPaymentRequest(customerId!, account['shop_id'], amount);
    if (result['success'] == true) {
      _fetchAccounts();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cash request sent to shop owner."), backgroundColor: Colors.green));
    } else {
      _showErrorDialog(result['message']);
    }
  }

  // --- RAZORPAY LOGIC ---
  Future<void> _startRazorpayFlow(Map<String, dynamic> account, double amount) async {
    final customerId = await SessionManager.getCustomerId();
    final result = await ApiService.createKhataRazorpayOrder(customerId!, account['shop_id'], amount);
    
    if (result != null && result['success'] == true) {
      _pendingBackendOrderId = result['backend_order_id'];
      _pendingAmount = amount;
      String rzpOrderId = result['razorpay_order_id'];

      var options = {
        'key': 'rzp_test_RKK3DuGSaxK9fR', // ✅ REAL KEY
        'amount': (amount * 100).toInt(),
        'name': account['shop_name'] ?? "Shop",
        'description': 'Khata Payment',
        'order_id': rzpOrderId,
        'currency': 'INR',
        'prefill': {'contact': '9999999999', 'email': 'user@grocery.com'}
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        print(e);
      }
    }
  }

  void _showErrorDialog(String msg) {
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text("Error"), content: Text(msg), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Khata"), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: Column(
        children: [
          if (_lastUpdated.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Last Updated: $_lastUpdated", style: const TextStyle(color: Colors.grey)),
            ),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _accounts.isEmpty
                  // ✅ FIX: Added Empty State Widget
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text("No Khata Accounts Found", style: TextStyle(color: Colors.grey, fontSize: 18)),
                          const SizedBox(height: 8),
                          const Text("Ask a Shop Owner to create one for you.", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: _accounts.length,
                      itemBuilder: (ctx, i) => KhataAccountCard(
                        account: _accounts[i],
                        onTap: () => _openDetailScreen(_accounts[i]),
                        onPayClick: () => _showPaymentOptions(_accounts[i]),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

// --- CARD WIDGET ---
class KhataAccountCard extends StatelessWidget {
  final Map<String, dynamic> account;
  final VoidCallback onTap;
  final VoidCallback onPayClick;

  const KhataAccountCard({super.key, required this.account, required this.onTap, required this.onPayClick});

  @override
  Widget build(BuildContext context) {
    String shopName = account['shop_name'] ?? "Unknown Shop"; 
    String phone = account['phone'] ?? "N/A";
    double balance = double.tryParse(account['balance']?.toString() ?? "0") ?? 0.0;
    double absBal = balance.abs();
    
    String statusText = "CLEAR";
    Color statusColor = Colors.grey;

    if (account['pending_status'] == 'pending') {
      statusText = "PENDING CASH";
      statusColor = Colors.orange;
    } else if (balance > 0) {
      statusText = "DUE";
      statusColor = Colors.red;
    } else if (balance < 0) {
      statusText = "ADVANCE";
      statusColor = Colors.green;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(4)),
                    child: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 5),
              Text("Phone: $phone", style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("₹${absBal.toStringAsFixed(2)}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: balance > 0 ? Colors.red : Colors.green)),
                  if (balance > 0 && account['pending_status'] != 'pending')
                    ElevatedButton(
                      onPressed: onPayClick,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                      child: const Text("Pay Now"),
                    )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
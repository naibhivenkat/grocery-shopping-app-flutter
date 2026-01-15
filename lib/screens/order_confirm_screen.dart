import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../services/api_service.dart';
import '../services/cart_manager.dart';
import '../services/session_manager.dart';
import '../managers/order_manager.dart';
import '../managers/payment_manager.dart';
import 'thank_you_screen.dart';

class OrderConfirmScreen extends StatefulWidget {
  final String shopId;
  final double total;
  final List<CartItem> cartItems;

  const OrderConfirmScreen({
    super.key,
    required this.shopId,
    required this.total,
    required this.cartItems,
  });

  @override
  State<OrderConfirmScreen> createState() => _OrderConfirmScreenState();
}

class _OrderConfirmScreenState extends State<OrderConfirmScreen> {
  late double _totalAmount;
  double _payNowAmount = 0.0;
  double _dueAmount = 0.0;

  String _selectedPaymentMethod = "";
  double _walletBalance = 0.0;
  bool _isWalletChecked = false;
  bool _isLoading = false;

  late OrderManager _orderManager;
  late PaymentManager _paymentManager;

  final TextEditingController _payNowController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _totalAmount = widget.total;
    _payNowAmount = _totalAmount;
    _payNowController.text = _payNowAmount.toStringAsFixed(2);
    _calculateDue();

    _orderManager = OrderManager(context);
    _paymentManager = PaymentManager(
      onError: (msg) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      },
      onPaymentVerified: (String backendOrderId) { // ✅ Updated to accept orderId
        if (!mounted) return;
        _finishOrder(backendOrderId);
      },
    );
  }

  @override
  void dispose() {
    _paymentManager.dispose();
    _payNowController.dispose();
    super.dispose();
  }

  void _calculateDue() {
    setState(() {
      if (_payNowAmount > _totalAmount) {
        _payNowAmount = _totalAmount;
        _payNowController.text = _payNowAmount.toStringAsFixed(2);
        _payNowController.selection =
            TextSelection.collapsed(offset: _payNowController.text.length);
      }
      _dueAmount = _totalAmount - _payNowAmount;
      if (_dueAmount < 0) _dueAmount = 0;
    });
  }

  void _selectPayment(String method) {
    setState(() {
      _selectedPaymentMethod = method;

      if (method == "Khata") {
        _payNowAmount = 0.0;
        _payNowController.text = "0.00";
        _calculateDue();
      } else if (_payNowAmount == 0) {
        _payNowAmount = _totalAmount;
        _payNowController.text = _payNowAmount.toStringAsFixed(2);
        _calculateDue();
      }
    });
  }

  Future<void> _checkWalletBalance() async {
    final customerId = await SessionManager.getCustomerId();
    if (customerId == null) return;

    setState(() => _isLoading = true);
    final balance = await ApiService.getWalletBalance(customerId);

    if (!mounted) return;
    setState(() {
      _walletBalance = balance;
      _isWalletChecked = true;
      _isLoading = false;
    });
  }

  // ---------------- PLACE ORDER ----------------
  void _handlePlaceOrder() async {
    if (_selectedPaymentMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select a Payment Method")),
      );
      return;
    }

    if (_selectedPaymentMethod == "Wallet") {
      if (!_isWalletChecked) await _checkWalletBalance();
      if (_walletBalance < _payNowAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Insufficient Wallet Balance!")),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    String backendMethod = "Cash";
    if (_selectedPaymentMethod == "UPI") backendMethod = "Razorpay";
    if (_selectedPaymentMethod == "Wallet") backendMethod = "Wallet";
    if (_selectedPaymentMethod == "Khata") backendMethod = "Khata";

    _orderManager.placeOrder(
      cartItems: widget.cartItems,
      shopId: widget.shopId,
      paymentMethod: backendMethod,
      transactionId: "", // MUST exist (matches Kotlin)
      payNowAmount: _payNowAmount,
      dueAmount: _dueAmount,

      onSuccess: (backendOrderId, razorpayOrderId, method) {

        if (method == "Razorpay") {

          // 🔐 REQUIRED: Razorpay verification needs order_id
          if (razorpayOrderId == null || razorpayOrderId.isEmpty) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Payment initialization failed. Please try again."),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          _paymentManager.startRazorpayCheckout(
            shopName: "Grocery App",
            totalAmount: _payNowAmount,
            razorpayOrderId: razorpayOrderId,
            backendOrderId: backendOrderId!,
          );
        } else {
          // Cash, Wallet, Khata -> directly finish
          // Ensure backendOrderId is passed
          _finishOrder(backendOrderId ?? "UNKNOWN_ORDER_ID"); 
        }
      },

      onError: (msg) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      },
    );
  }

  // ✅ Updated to accept orderId
  void _finishOrder(String orderId) {
    CartManager().clearCart(widget.shopId);
    
    // Navigate to Thank You Screen with correct params
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ThankYouScreen(
          orderId: orderId,      // Pass the specific order ID
          shopId: widget.shopId, // Pass the shop ID
        ),
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Order"), backgroundColor: Colors.green),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // TOTAL CARD
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text("Total Payable"),
                          Text(
                            "₹${_totalAmount.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // PAY NOW
                  TextField(
                    controller: _payNowController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Pay Now Amount (₹)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    enabled: _selectedPaymentMethod != "Khata",
                    onChanged: (val) {
                      final value = double.tryParse(val);
                      if (value != null) {
                        _payNowAmount = value;
                        _calculateDue();
                      }
                    },
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Due Amount: ₹${_dueAmount.toStringAsFixed(2)}",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _dueAmount > 0 ? Colors.red : Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Payment Method",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  _buildPaymentOption("UPI", Icons.qr_code, Colors.blue),
                  _buildPaymentOption("Cash", Icons.money, Colors.green),
                  _buildPaymentOption("Khata", Icons.book, Colors.orange),

                  Card(
                    elevation: _selectedPaymentMethod == "Wallet" ? 4 : 1,
                    color: _selectedPaymentMethod == "Wallet"
                        ? Colors.green.shade50
                        : Colors.white,
                    child: ListTile(
                      leading: const Icon(Icons.account_balance_wallet, color: Colors.purple),
                      title: const Text("Wallet"),
                      subtitle: _isWalletChecked
                          ? Text("Balance: ₹${_walletBalance.toStringAsFixed(2)}")
                          : const Text("Check balance to pay"),
                      trailing: TextButton(
                        onPressed: _checkWalletBalance,
                        child: const Text("Check"),
                      ),
                      onTap: () {
                        if (!_isWalletChecked) _checkWalletBalance();
                        _selectPayment("Wallet");
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _handlePlaceOrder,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text(
                        "PLACE ORDER",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentOption(String label, IconData icon, Color color) {
    final isSelected = _selectedPaymentMethod == label;

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.green.shade50 : Colors.white,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing:
            isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
        onTap: () => _selectPayment(label),
      ),
    );
  }
}
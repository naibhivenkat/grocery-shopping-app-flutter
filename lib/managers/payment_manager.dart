import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/api_service.dart';

class PaymentManager {
  late Razorpay _razorpay;
  final Function(String) onError;
  
  // ✅ FIX 1: Change callback type to accept a String (orderId)
  final Function(String) onPaymentVerified;

  String? _currentBackendOrderId;

  PaymentManager({
    required this.onError,
    required this.onPaymentVerified,
  }) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void startRazorpayCheckout({
    required String shopName,
    required double totalAmount,
    required String razorpayOrderId,
    required String backendOrderId,
  }) {
    _currentBackendOrderId = backendOrderId;

    var options = {
      'key': 'rzp_test_RKK3DuGSaxK9fR', // Replace with your actual key
      'amount': (totalAmount * 100).toInt(),
      'name': shopName,
      'description': 'Grocery Order',
      'order_id': razorpayOrderId,
      'prefill': {'contact': '9999999999', 'email': 'user@example.com'},
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      onError("Razorpay Error: $e");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_currentBackendOrderId == null) return;

    final success = await ApiService.verifyPayment({
      "backend_order_id": _currentBackendOrderId,
      "payment_id": response.paymentId,
      "order_id": response.orderId,
      "signature": response.signature
    });

    if (success) {
      // ✅ FIX 2: Pass the backendOrderId back to the screen
      onPaymentVerified(_currentBackendOrderId!);
    } else {
      onError("Payment Verification Failed");
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    onError("Payment Failed: ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    onError("External Wallet Selected: ${response.walletName}");
  }

  void dispose() {
    _razorpay.clear();
  }
}
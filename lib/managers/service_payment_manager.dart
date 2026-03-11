import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../service_module/provider/api/service_api.dart';

class ServicePaymentManager {
  late Razorpay _razorpay;

  final Function(String) onError;
  final Function(String) onPaymentVerified;

  String? _currentBackendOrderId;

  ServicePaymentManager({
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
      'key': 'rzp_test_RKK3DuGSaxK9fR',
      'amount': (totalAmount * 100).toInt(),
      'name': shopName,
      'description': 'Service Booking',
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

    final success = await ServiceApi.verifyServicePayment({
      "backend_order_id": _currentBackendOrderId,
      "payment_id": response.paymentId,
      "order_id": response.orderId,
      "signature": response.signature
    });

    if (success) {
      onPaymentVerified(_currentBackendOrderId!);
    } else {
      onError("Payment verification failed");
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    onError("Payment failed: ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    onError("External wallet selected: ${response.walletName}");
  }

  void dispose() {
    _razorpay.clear();
  }
}

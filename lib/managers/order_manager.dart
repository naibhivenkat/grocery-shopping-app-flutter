import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../services/api_service.dart';

class OrderManager {
  final BuildContext context;
  OrderManager(this.context);

  Future<void> placeOrder({
    required List<CartItem> cartItems,
    required String shopId,
    required String paymentMethod,
    required String transactionId,
    required double payNowAmount,
    required double dueAmount,
    required Function(String? backendOrderId, String? razorpayOrderId, String method) onSuccess,
    required Function(String message) onError,
  }) async {

    final itemsPayload = cartItems.map((c) => {
      "item_id": c.item.id,
      "quantity": c.quantity,
    }).toList();

    final Map<String, dynamic> orderData = {
      "shopId": shopId,
      "payment_method": paymentMethod,
      "items": itemsPayload,

      // 🔐 REQUIRED (matches Kotlin)
      "transaction_id": transactionId, // empty string is OK

      "pay_now": payNowAmount,
      "due_amount": dueAmount,
    };

    debugPrint("📤 OrderManager Final Payload: $orderData");

    final result = await ApiService.createOrder(orderData);
    debugPrint("📥 Order API Response: $result");

    if (result['success'] == true) {
      final data = result['data'] ?? result;

      onSuccess(
        data['order_id'],
        data['razorpay_order_id'], // MUST exist for Razorpay
        paymentMethod,
      );
    } else {
      onError(result['message'] ?? "Failed to place order");
    }
  }
}

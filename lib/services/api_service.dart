import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/shop_model.dart';
import '../models/item_model.dart';
import 'session_manager.dart';
import '../models/wallet_transaction_model.dart'; 

class ApiService {
  // 1. Base URL
  static const String baseUrl = "https://grocery-backend-956424262985.asia-south1.run.app";

  // 2. Helper to get Headers (Includes Auth Token)
  static Future<Map<String, String>> getHeaders() async {
    String? token = await SessionManager.getAuthToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // --- LOGIN ---
  // Kotlin: @POST("login")
  static Future<LoginResponse?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );
      if (response.statusCode == 200) {
        return LoginResponse.fromJson(jsonDecode(response.body));
      } else {
        return LoginResponse(success: false, message: "Error: ${response.statusCode}");
      }
    } catch (e) {
      return LoginResponse(success: false, message: "Connection Error: $e");
    }
  }

  // --- GET ALL SHOPS ---
  // Kotlin: @GET("api/shops")
  static Future<List<Shop>> getAllShops() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/api/shops'), headers: headers);

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => Shop.fromJson(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching shops: $e");
      return [];
    }
  }

  // --- GET ITEMS FOR SHOP ---
  // Kotlin: @GET("api/shops/{shop_id}/items")
  static Future<List<Item>> getItems(String shopId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/shops/$shopId/items'),
        headers: headers
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> itemsJson = data['items'] ?? [];
        return itemsJson.map((json) => Item.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching items: $e");
      return [];
    }
  }

  // --- WALLET: Get Balance ---
  // Kotlin: @GET("/wallet/{user_id}")
  static Future<double> getWalletBalance(String customerId) async {
    try {
      final headers = await getHeaders();
      // ✅ FIXED ENDPOINT
      final response = await http.get(
        Uri.parse('$baseUrl/wallet/$customerId'), 
        headers: headers
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle Kotlin structure: WalletBalanceResponse(val balance: Double)
        if (data['balance'] != null) {
          return (data['balance'] as num).toDouble();
        } 
      }
    } catch (e) {
      print("Error fetching wallet: $e");
    }
    return 0.0;
  }

  // --- ORDER: Create Order ---
  // Kotlin: @POST("api/place_orders")
  static Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    try {
      final headers = await getHeaders();
      
      // ⚠️ IMPORTANT: Kotlin model uses "shopId" (camelCase), not "shop_id"
      // We fix the key here just in case the UI sent "shop_id"
      if (orderData.containsKey('shop_id')) {
        orderData['shopId'] = orderData['shop_id'];
        orderData.remove('shop_id');
      }

      // ✅ FIXED ENDPOINT
      final response = await http.post(
        Uri.parse('$baseUrl/api/place_orders'), 
        headers: headers,
        body: jsonEncode(orderData),
      );
      
      // Debug print to see server response
      print("Order API Response: ${response.body}");

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? "Order failed"};
      }
    } catch (e) {
      return {'success': false, 'message': "Connection Error: $e"};
    }
  }

  // --- PAYMENT: Verify (For Razorpay) ---
  // Kotlin: @POST("/api/verify_payment")
  static Future<bool> verifyPayment(Map<String, dynamic> verifyData) async {
    try {
      final headers = await getHeaders();
      // ✅ FIXED ENDPOINT
      final response = await http.post(
        Uri.parse('$baseUrl/api/verify_payment'), 
        headers: headers,
        body: jsonEncode(verifyData),
      );

      print("Verify Payment Response: ${response.body}");

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print("Verify Error: $e");
    }
    return false;
  }

  // --- HEALTH CHECK ---
  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/internal-healthz'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
// --- GET SHOP ORDERS (For Shop Owner) ---
  static Future<List<dynamic>> getShopOrders(String shopId) async {
    try {
      final headers = await getHeaders();
      final url = Uri.parse('$baseUrl/api/get_shopkeeper_orders/shopkeeper/$shopId');
      
      print("📤 Fetching Orders: $url"); // Debug URL

      final response = await http.get(url, headers: headers);

      print("📥 Orders Response Code: ${response.statusCode}"); // Debug Code
      print("📥 Orders Body: ${response.body}"); // Debug Body

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching shop orders: $e");
      return [];
    }
  }

  // --- GET CUSTOMER ORDERS ---
  static Future<List<dynamic>> getCustomerOrders(String customerId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/get_customers_orders/customer/$customerId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching customer orders: $e");
      return [];
    }
  }

  // --- ORDER DETAILS ---
  static Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/get_order_details/$orderId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error fetching order details: $e");
    }
    return null;
  }



  // --- CREATE WALLET ORDER (For Add Money) ---
  static Future<Map<String, dynamic>?> createWalletOrder(String userId, double amount) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/create_wallet_order'),
        headers: headers,
        body: jsonEncode({"user_id": userId, "amount": amount}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error creating wallet order: $e");
    }
    return null;
  }

  // --- VERIFY WALLET PAYMENT ---
  static Future<bool> verifyWalletPayment(Map<String, dynamic> data) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/verify_wallet_payment'),
        headers: headers,
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- WALLET TRANSACTIONS ---
  static Future<List<WalletTransaction>> getWalletTransactions(String userId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/wallet/transactions/$userId'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        // ✅ Convert JSON list to Model list
        return body.map((item) => WalletTransaction.fromJson(item)).toList();
      }
    } catch (e) {
      print("Error fetching transactions: $e");
    }
    return [];
  }

  // --- KHATA: Get Customer Accounts ---
static Future<List<dynamic>> getMyKhataAccounts(String customerId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/khata/my_accounts/$customerId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['accounts'] ?? [];
      }
    } catch (e) {
      print("Error fetching my khata: $e");
    }
    return [];
  }

  // --- KHATA: Pay with Wallet ---
  static Future<Map<String, dynamic>> payKhataWallet(String customerId, String shopId, double amount) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/khata/pay_khata_from_wallet'),
        headers: headers,
        body: jsonEncode({
          "customer_id": customerId,
          "shop_id": shopId,
          "amount": amount
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network Error'};
    }
  }

  // --- KHATA: Cash Payment Request ---
  static Future<Map<String, dynamic>> createCashPaymentRequest(String customerId, String shopId, double amount) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/khata/cash_payment_request'),
        headers: headers,
        body: jsonEncode({
          "customer_id": customerId,
          "shop_id": shopId,
          "amount": amount
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network Error'};
    }
  }

  // --- KHATA: Create Razorpay Order ---
  static Future<Map<String, dynamic>?> createKhataRazorpayOrder(String customerId, String shopId, double amount) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/khata/create_razorpay_order'),
        headers: headers,
        body: jsonEncode({
          "customer_id": customerId,
          "shop_id": shopId,
          "amount": amount
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error creating khata order: $e");
    }
    return null;
  }

  // --- KHATA: Verify Razorpay Payment ---
  static Future<bool> verifyKhataRazorpayPayment(Map<String, dynamic> data) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/khata/verify_razorpay_payment'),
        headers: headers,
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- KHATA: Get Ledger Details (Transactions) ---
 static Future<Map<String, dynamic>?> getKhataLedger(String shopId, String customerId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/khata/ledger/$shopId/$customerId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error fetching ledger: $e");
    }
    return null;
  }

  // --- UPDATE PROFILE ---
  static Future<bool> updateProfile(Map<String, String> profileData) async {
    try {
      // Endpoint matches Kotlin logic (likely '/update_profile')
      // Assuming your Kotlin ApiClient uses baseUrl
      final response = await http.post(
        Uri.parse('$baseUrl/update_profile'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(profileData),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error updating profile: $e");
      return false;
    }
  }

  // --- CHANGE PASSWORD ---
  static Future<Map<String, dynamic>> changePassword(String username, String oldPassword, String newPassword) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/change_password'), // Adjust endpoint if needed
        headers: headers,
        body: jsonEncode({
          "username": username,
          "old_password": oldPassword,
          "new_password": newPassword
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return error message from backend if available
        final body = jsonDecode(response.body);
        return {'success': false, 'message': body['message'] ?? 'Failed to change password'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    }
  }

 // ==========================================
  //  SHOP WALLET API (Correct Python Paths)
  // ==========================================

  // ✅ FIX: Use '/shop/wallet/<shopId>'
  static Future<double> getShopWalletBalance(String shopId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        // Matches Python: @shop_wallet_bp.route("/shop/wallet/<shop_id>")
        Uri.parse('$baseUrl/shop/wallet/$shopId'), 
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return double.tryParse(data['balance'].toString()) ?? 0.0;
      }
    } catch (e) {
      print("Error fetching shop balance: $e");
    }
    return 0.0;
  }

  // ✅ FIX: Use '/shop/wallet/transactions/<shopId>'
  static Future<List<dynamic>> getShopWalletTransactions(String shopId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        // Matches Python: @shop_wallet_bp.route("/shop/wallet/transactions/<shop_id>")
        Uri.parse('$baseUrl/shop/wallet/transactions/$shopId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
    } catch (e) {
      print("Error fetching shop transactions: $e");
    }
    return [];
  }

  // --- KHATA: Get Shop Customers ---
static Future<List<dynamic>> getKhataCustomers(String shopId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/khata/customers/$shopId'), // Matches backend @khata_bp.route("/customers/<shop_id>")
        headers: headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['accounts'] ?? [];
      }
    } catch (e) {
      print("Error fetching shop khata: $e");
    }
    return [];
  }

  // --- KHATA: Create New Ledger ---
static Future<bool> createKhataLedger(Map<String, dynamic> payload) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/khata/create_ledger'), // ✅ Fixed URL
        headers: headers,
        body: jsonEncode(payload),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error creating khata: $e");
      return false;
    }
  }

  static Future<bool> addKhataTransaction(Map<String, dynamic> payload) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/khata/add_transaction'),
        headers: headers,
        body: jsonEncode(payload),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> approveCashPayment(String shopId, String customerId) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/khata/approve_cash_payment'),
        headers: headers,
        body: jsonEncode({"shop_id": shopId, "customer_id": customerId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  static Future<bool> rejectCashPayment(String shopId, String customerId) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/khata/reject_cash_payment'),
        headers: headers,
        body: jsonEncode({"shop_id": shopId, "customer_id": customerId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- USER: Get All Customers (For creating Khata) ---
  static Future<List<dynamic>> getAllCustomers() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/customers'), // ✅ Calls the new Python endpoint
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['customers'] ?? [];
      }
    } catch (e) {
      print("Error fetching customers: $e");
    }
    return [];
  }

  // --- ITEMS: Get Items for Shop ---
  static Future<List<dynamic>> getShopItems(String shopId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/shops/$shopId/items'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['items'] ?? [];
      }
    } catch (e) {
      print("Error fetching items: $e");
    }
    return [];
  }

  // --- ITEMS: Update Item ---
  static Future<bool> updateItem(String itemId, Map<String, dynamic> data) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/items/$itemId'),
        headers: headers,
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['success'] == true;
      }
    } catch (e) {
      print("Error updating item: $e");
    }
    return false;
  }

  // --- ITEMS: Delete Item ---
  static Future<bool> deleteItem(String itemId) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/items/$itemId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['success'] == true;
      }
    } catch (e) {
      print("Error deleting item: $e");
    }
    return false;
  }

 
  // --- ITEMS: Add New Items (Shop Owner) ---
  static Future<bool> addShopItems(String shopId, List<Map<String, dynamic>> items) async {
    try {
      final headers = await getHeaders(); 
      final response = await http.post(
        Uri.parse('$baseUrl/shop/add_items'), 
        headers: headers,
        body: jsonEncode({
          "shop_id": shopId,
          "items": items
        }),
      );

      // ✅ FIX: Accept 200 (OK) AND 201 (Created)
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("Failed to add items (${response.statusCode}): ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error adding items: $e");
      return false;
    }
  }

  // --- PASSWORD RESET: Step 1 - Send OTP ---
  static Future<Map<String, dynamic>> sendPasswordResetOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send_password_reset_otp'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    }
  }

  // --- PASSWORD RESET: Step 2 - Verify OTP ---
  static Future<Map<String, dynamic>> verifyPasswordResetOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify_password_reset_otp'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "otp": otp}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    }
  }

  // --- PASSWORD RESET: Step 3 - Update Password ---
  static Future<Map<String, dynamic>> updatePassword(String email, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/update_password'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": newPassword}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network Error: $e'};
    }
  }

  // --- RATE SHOP ---
  static Future<bool> rateShop(Map<String, dynamic> data) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/rate_shop'),
        headers: headers,
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['success'] == true;
      }
    } catch (e) {
      print("Error rating shop: $e");
    }
    return false;
  }

  // --- ANALYTICS: Get Shop Rating Overview ---
  static Future<Map<String, dynamic>?> getShopRatingAnalytics(String shopId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/shop_rating_analytics/$shopId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error fetching analytics: $e");
    }
    return null;
  }

  // --- ANALYTICS: Get Reviews by Rating ---
  static Future<List<dynamic>> getShopReviewsByRating(String shopId, int rating) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        // Matches Python: @GET("/shop/reviews") with query params
        Uri.parse('$baseUrl/shop/reviews?shop_id=$shopId&rating=$rating'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reviews'] ?? [];
      }
    } catch (e) {
      print("Error fetching reviews: $e");
    }
    return [];
  }

  // --- UPDATE ORDER STATUS ---
  static Future<bool> updateOrderStatus(Map<String, dynamic> body) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/update_order_status'),
        headers: headers,
        body: jsonEncode(body),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error updating status: $e");
      return false;
    }
  }

  // --- UPDATE ORDER ITEMS (Supports Refund & Extra Payment) ---
  static Future<bool> updateOrderItems(String orderId, List<Map<String, dynamic>> items, {String? refundMode, String? dueMode}) async {
    try {
      final headers = await getHeaders();
      
      final Map<String, dynamic> body = {
        "items": items,
      };
      
      if (refundMode != null) body["refund_mode"] = refundMode;
      if (dueMode != null) body["due_mode"] = dueMode; // ✅ Added

      final response = await http.patch(
        Uri.parse('$baseUrl/api/update_order_items/$orderId'), 
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        // Print error for debugging (e.g. Low Wallet Balance)
        print("Update Failed: ${response.body}"); 
        return false;
      }
    } catch (e) {
      print("Error updating items: $e");
      return false;
    }
  }

  // --- CONFIRM EXTRA PAYMENT (Customer Side) ---
static Future<bool> confirmExtraPayment(String orderId, String mode) async {
  try {
    final res = await http.post(
      Uri.parse("$baseUrl/api/confirm_extra_payment"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "order_id": orderId,
        "payment_mode": mode,
      }),
    );

    final data = jsonDecode(res.body);
    return data["success"] == true;
  } catch (e) {
    return false;
  }
}


  static Future<Map<String, dynamic>?> createExtraPaymentRazorpayOrder(String orderId) async {
  try {
    final res = await http.post(
      Uri.parse("$baseUrl/api/create_extra_payment_order"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "order_id": orderId,
        "payment_mode": "UPI" // ✅ IMPORTANT
      }),
    );

    return jsonDecode(res.body);
  } catch (e) {
    return null;
  }
}



static Future<bool> verifyExtraPayment({
  required String orderId,
  required String razorpayOrderId,
  required String paymentId,
  required String signature,
}) async {
  try {
    final res = await http.post(
      Uri.parse("$baseUrl/api/verify_extra_payment"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "order_id": orderId,
        "razorpay_order_id": razorpayOrderId,
        "payment_id": paymentId,
        "signature": signature,
      }),
    );

    final data = jsonDecode(res.body);
    return data["success"] == true;
  } catch (e) {
    return false;
  }
}


  
  }
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../models/wallet_transaction_model.dart';
import '../../../services/session_manager.dart';

class ServiceApi {
  static const String baseUrl =
      "https://grocery-backend-956424262985.asia-south1.run.app";

  static Uri _uri(String path) => Uri.parse("$baseUrl/service$path");

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      _uri(path),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw Exception(data["error"] ?? "Request failed");
    }
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    final res = await http.get(_uri(path));
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      throw Exception(data["error"] ?? "Request failed");
    }
    return Map<String, dynamic>.from(data);
  }

  // ✅ OTP
static Future<void> sendOtp({required String email}) async {
  final res = await http.post(
    Uri.parse("$baseUrl/send_otp"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"email": email}),
  );

  final data = jsonDecode(res.body);
  if (res.statusCode >= 400 || data["status"] != "success") {
    throw Exception(data["message"] ?? "Failed to send OTP");
  }
}

static Future<void> verifyOtp({required String email, required String otp}) async {
  final res = await http.post(
    Uri.parse("$baseUrl/verify_otp"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"email": email, "otp": otp}),
  );

  final data = jsonDecode(res.body);
  if (res.statusCode >= 400 || data["status"] != "success") {
    throw Exception(data["message"] ?? "OTP verification failed");
  }
}


  // ✅ Auth
  static Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    return _post("/auth/register", payload);
  }

  static Future<Map<String, dynamic>> login({required String email, required String password}) async {
    return _post("/auth/login", {"email": email, "password": password});
  }

  static Future<void> forgotPassword({required String email, required String newPassword}) async {
    await _post("/auth/forgot_password", {"email": email, "new_password": newPassword});
  }

  // ✅ Provider services
  static Future<List<dynamic>> getMyServices(String providerId) async {
    final data = await _get("/provider/$providerId/services");
    return data["services"] ?? [];
  }

  static Future<Map<String, dynamic>> addOrUpdateService(Map<String, dynamic> payload) async {
    return _post("/provider/services/upsert", payload);
  }

  // ✅ Availability
  static Future<Map<String, dynamic>> getAvailability(String providerId, String date) async {
    return _get("/provider/$providerId/availability?date=$date");
  }

  static Future<Map<String, dynamic>> updateSlots(Map<String, dynamic> payload) async {
    return _post("/provider/availability/update_slots", payload);
  }

  // ✅ Bookings
  static Future<List<dynamic>> providerBookings(String providerId, String status) async {
    final data = await _get("/provider/$providerId/bookings?status=$status");
    return data["bookings"] ?? [];
  }

  static Future<Map<String, dynamic>> bookingDetail(String bookingId) async {
    return _get("/bookings/$bookingId");
  }

  static Future<void> acceptBooking({required String bookingId, required String providerId}) async {
    await _post("/bookings/$bookingId/accept", {"provider_id": providerId});
  }

  static Future<void> rejectBooking({
    required String bookingId,
    required String providerId,
    required String reason,
  }) async {
    await _post("/bookings/$bookingId/reject", {"provider_id": providerId, "reason": reason});
  }

  static Future<void> startService({required String bookingId, required String providerId}) async {
    await _post("/bookings/$bookingId/start", {"provider_id": providerId});
  }

  static Future<void> completeService({required String bookingId, required String providerId}) async {
    await _post("/bookings/$bookingId/complete", {"provider_id": providerId});
  }

  // ✅ Earnings
  static Future<Map<String, dynamic>> earningsSummary(String providerId) async {
    return _get("/provider/$providerId/earnings/summary");
  }

  static Future<Map<String, dynamic>> getProviderEarningsDashboard(String providerId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/service/provider/dashboard/earnings?provider_id=$providerId"),
  );

  final json = jsonDecode(res.body);
  return json;
}


  // ✅ Ratings
  static Future<Map<String, dynamic>> ratings(String providerId) async {
    return _get("/provider/$providerId/ratings");
  }

static Future<void> deleteService(String id) async {
  await _delete("/service/provider/services/$id");
}


static Future<void> _delete(String path) async {
  final res = await http.delete(
    Uri.parse("$baseUrl$path"),
    headers:  {"Content-Type": "application/json"}
  );

  if (res.statusCode != 200) {
    final data = jsonDecode(res.body);
    throw Exception(data["message"] ?? "Delete failed");
  }
}

static Future<Map<String, dynamic>> getServiceDetails(
  String providerId,
  String serviceId,
) async {
  final res = await _get(
    "/provider/$providerId/service/$serviceId",
  );
  return res;
}
  // =========================
  // BOOK SERVICE
  // =========================
static Future<Map<String, dynamic>> bookService(
    Map<String, dynamic> payload) async {
  return _post("/bookings", payload);
}


static Future<List<dynamic>> getAvailableServicesByCategory(
  String categoryId,
) async {
  final requesterId = await SessionManager.getServiceUserId();
  final lat = await SessionManager.getUserLat();
  final lng = await SessionManager.getUserLng();

  final uri = Uri.parse("$baseUrl/service/available").replace(
    queryParameters: {
      "category_id": categoryId,
      "requester_id": requesterId,
      if (lat != null) "lat": lat.toString(),
      if (lng != null) "lng": lng.toString(),
      "page": "1",
      "limit": "20",
    },
  );

  final res = await http.get(uri);

  if (res.statusCode != 200) {
    throw Exception("Failed to load providers");
  }

  final body = jsonDecode(res.body);

  /// ⭐ HANDLE ALL POSSIBLE API RESPONSES
  if (body is Map) {
    if (body.containsKey("data") && body["data"] is List) {
      return body["data"];
    }

    /// single provider case
    return [body];
  }

  if (body is List) {
    return body;
  }

  return [];
}


static Future<Map<String, dynamic>> calculateServicePrice(
    Map<String, dynamic> payload) async {
  return _post("/calculate-price", payload);
}


static Future<double> getWalletBalance(String userId) async {
  final res = await http.get(Uri.parse("$baseUrl/service/wallet/$userId/balance"));

  if (res.statusCode != 200) return 0;

  final decoded = json.decode(res.body);

  if (decoded is Map && decoded["balance"] != null) {
    return (decoded["balance"] as num).toDouble();
  }

  if (decoded["data"] != null) {
    return (decoded["data"]["balance"] as num).toDouble();
  }

  return 0;
}


static Future<void> deductWallet(Map<String, dynamic> payload) async {
  await http.post(
    Uri.parse("$baseUrl/wallet/deduct"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(payload),
  );
}

static Future<Map<String, dynamic>> createRazorpayOrder(
    Map<String, dynamic> payload) async {
  return _post("/payment/create-order", payload);
}


static Future<bool> verifyServicePayment(Map payload) async {
  final res = await http.post(
    Uri.parse("$baseUrl/service/payment/verify"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(payload),
  );
  return res.statusCode == 200;
}


// WALLET BALANCE
static Future<Map<String, dynamic>> servicegetWalletBalance(String userId) async {
  final res = await http.get(Uri.parse("$baseUrl/service/wallet/$userId/balance"));
  return jsonDecode(res.body);
}


static Future<List<WalletTransaction>> getWalletTransactions(String userId) async {
  final res = await http.get(Uri.parse("$baseUrl/service/wallet/$userId/transactions"));

  if (res.statusCode != 200) return [];

  final decoded = json.decode(res.body);

  if (decoded is List) {
    return decoded.map((e) => WalletTransaction.fromJson(e)).toList();
  }

  // backend returned {success:true} or anything unexpected
  return [];
}


// CREATE ORDER
static Future<Map<String, dynamic>> createWalletOrder(String userId, double amount) async {
  final res = await http.post(
    Uri.parse("$baseUrl/service/wallet/create-order"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"user_id": userId, "amount": amount}),
  );
  return jsonDecode(res.body);
}

// VERIFY PAYMENT
static Future<bool> verifyWalletPayment(Map payload) async {
  final res = await http.post(
    Uri.parse("$baseUrl/service/wallet/verify"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(payload),
  );
  return res.statusCode == 200;
}

// DEDUCT
static Future<void> servicedeductWallet(Map payload) async {
  await http.post(
    Uri.parse("$baseUrl/service/wallet/deduct"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(payload),
  );
}

static Future<Map<String, dynamic>> createPendingBooking(Map body) async {
  final res = await http.post(
    Uri.parse("$baseUrl/service/booking/create-pending"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(body),
  );

  final data = jsonDecode(res.body);

  if (res.statusCode >= 400) {
    throw Exception(data["error"] ?? "Failed to create booking");
  }

  return Map<String, dynamic>.from(data);
}



static Future<Map<String, dynamic>> confirmBooking(Map body) async {
  final res = await http.post(
    Uri.parse("$baseUrl/service/booking/confirm"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(body),
  );

  final data = jsonDecode(res.body);

  if (res.statusCode >= 400) {
    throw Exception(data["error"] ?? "Booking confirmation failed");
  }

  return Map<String, dynamic>.from(data);
}



static Future<Map> cancelBooking(String bookingId) async {
  final res = await http.post(Uri.parse("$baseUrl/service/booking/$bookingId/cancel"));
  return jsonDecode(res.body);
}

static Future<List> myBookings(String requesterId) async {
  final res = await http.get(Uri.parse("$baseUrl/service/customer/bookings/$requesterId"));
  return jsonDecode(res.body)["bookings"];
}


}


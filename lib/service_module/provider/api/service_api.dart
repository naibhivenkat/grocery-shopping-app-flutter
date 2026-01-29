import 'dart:convert';
import 'package:http/http.dart' as http;

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


}

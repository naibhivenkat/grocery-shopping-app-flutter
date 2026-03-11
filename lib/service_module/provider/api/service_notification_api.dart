import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/service_notification_model.dart';

class ServiceNotificationApi {

  static const baseUrl =
      "https://grocery-backend-956424262985.asia-south1.run.app";

  /// FETCH
  static Future<List<ServiceNotification>> fetch(String providerId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/service/notifications?provider_id=$providerId"),
    );

    if (res.statusCode != 200) {
      print("Fetch notifications failed: ${res.body}");
      return [];
    }

    final List data = jsonDecode(res.body);

    return data
        .map((e) => ServiceNotification.fromJson(e))
        .toList();
  }

  /// MARK ALL
  static Future<void> markAll(String providerId) async {
    await http.post(
      Uri.parse("$baseUrl/service/notifications/mark-all-read"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"provider_id": providerId}),
    );
  }

  /// MARK SINGLE
  static Future<void> markSingle(String notificationId) async {
    await http.post(
      Uri.parse("$baseUrl/service/notifications/mark-read"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"notification_id": notificationId}),
    );
  }
}


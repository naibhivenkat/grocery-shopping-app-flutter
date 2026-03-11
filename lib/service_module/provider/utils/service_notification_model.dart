import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final String providerId;
  final bool isRead;
  final String createdAt;
  final String? bookingId;

  /// ✅ NEW SNAPSHOT FIELDS
  final String? senderId;
  final String? senderName;
  final String? senderPhoto;

  ServiceNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.providerId,
    required this.isRead,
    required this.createdAt,
    this.bookingId,
    this.senderId,
    this.senderName,
    this.senderPhoto,
  });

  factory ServiceNotification.fromJson(Map<String, dynamic> json) {
    return ServiceNotification(
      id: json["id"] ?? "",
      title: json["title"] ?? "",
      body: json["body"] ?? "",
      type: json["type"] ?? "",
      providerId: json["provider_id"] ?? "",
      isRead: json["is_read"] ?? false,
      createdAt: _parseDate(json["created_at"]),

      /// 🔥 Booking ID Parse
      bookingId:
          json["booking_id"]?.toString() ??
          json["data"]?["booking_id"]?.toString() ??
          json["request_id"]?.toString(),

      /// ✅ NEW FIELDS
      senderId: json["sender_id"]?.toString(),
      senderName: json["sender_name"],
      senderPhoto: json["sender_photo"],
    );
  }

  static String _parseDate(dynamic value) {
    if (value == null) return "";

    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }

    if (value is String) return value;

    return "";
  }
}
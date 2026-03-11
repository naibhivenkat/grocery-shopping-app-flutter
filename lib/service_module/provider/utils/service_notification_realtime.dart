import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceNotificationRealtime {

  static Stream<int> unreadCountStream(String providerId) {
    return FirebaseFirestore.instance
        .collection("service_notifications")
        .where("provider_id", isEqualTo: providerId)
        .where("is_read", isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

}

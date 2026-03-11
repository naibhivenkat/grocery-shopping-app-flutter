import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../utils/service_notification_model.dart';
import 'chat_screen.dart';

class ServiceNotificationScreen extends StatefulWidget {
  final String providerId;

  const ServiceNotificationScreen({
    super.key,
    required this.providerId,
  });

  @override
  State<ServiceNotificationScreen> createState() =>
      _ServiceNotificationScreenState();
}

class _ServiceNotificationScreenState
    extends State<ServiceNotificationScreen> {

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  //////////////////////////////////////////////////////////////
  /// MARK SINGLE READ
  //////////////////////////////////////////////////////////////
  Future<void> _markRead(String id) async {
    try {
      await _db
          .collection("service_notifications")
          .doc(id)
          .update({"is_read": true});
    } catch (e) {
      debugPrint("markRead error: $e");
    }
  }

  //////////////////////////////////////////////////////////////
  /// MARK ALL READ
  //////////////////////////////////////////////////////////////
  Future<void> _markAllRead() async {
    try {
      final snap = await _db
          .collection("service_notifications")
          .where("provider_id", isEqualTo: widget.providerId)
          .where("is_read", isEqualTo: false)
          .get();

      final batch = _db.batch();

      for (var doc in snap.docs) {
        batch.update(doc.reference, {"is_read": true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint("markAll error: $e");
    }
  }

  //////////////////////////////////////////////////////////////
  /// OPEN NOTIFICATION
  //////////////////////////////////////////////////////////////
  Future<void> _openNotification(ServiceNotification n) async {
    try {
      if (!n.isRead) {
        await _markRead(n.id);
      }

      if (!mounted) return;

      final bookingId = n.bookingId;
      if (bookingId == null || bookingId.isEmpty) return;

      if (n.type == "booking") {
        Navigator.pushNamed(
          context,
          "/booking-detail",
          arguments: bookingId,
        );
        return;
      }

      if (n.type == "chat") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              bookingId: bookingId,
              myUserId: widget.providerId,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Notification open error: $e");
    }
  }

  //////////////////////////////////////////////////////////////
  /// STREAM
  //////////////////////////////////////////////////////////////
  Stream<QuerySnapshot> _stream() {
    return _db
        .collection("service_notifications")
        .where("provider_id", isEqualTo: widget.providerId)
        .orderBy("created_at", descending: true)
        .snapshots();
  }

  //////////////////////////////////////////////////////////////
  /// FORMAT TIME
  //////////////////////////////////////////////////////////////
  String _formatTime(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final time = DateFormat("hh:mm a").format(dt);

      if (now.difference(dt).inDays == 0) {
        return time;
      } else if (now.difference(dt).inDays == 1) {
        return "Yesterday • $time";
      } else {
        return "${DateFormat("dd MMM yyyy").format(dt)} • $time";
      }
    } catch (_) {
      return "";
    }
  }

  //////////////////////////////////////////////////////////////
  /// GROUP BY DATE
  //////////////////////////////////////////////////////////////
  Map<String, List<ServiceNotification>> _groupByDate(
      List<ServiceNotification> list) {

    final Map<String, List<ServiceNotification>> grouped = {};

    for (final n in list) {
      DateTime? dt;
      try {
        dt = DateTime.parse(n.createdAt).toLocal();
      } catch (_) {}

      if (dt == null) continue;

      final now = DateTime.now();
      String key;

      if (now.difference(dt).inDays == 0) {
        key = "Today";
      } else if (now.difference(dt).inDays == 1) {
        key = "Yesterday";
      } else {
        key = DateFormat("dd MMM yyyy").format(dt);
      }

      grouped.putIfAbsent(key, () => []).add(n);
    }

    return grouped;
  }

  //////////////////////////////////////////////////////////////
  /// TYPE ICON
  //////////////////////////////////////////////////////////////
  // Widget _typeIcon(ServiceNotification n) {
  //   IconData icon;
  //   Color bgColor;

  //   switch (n.type) {
  //     case "booking":
  //       icon = Icons.calendar_today;
  //       bgColor = Colors.blue.shade100;
  //       break;
  //     case "chat":
  //       icon = Icons.chat_bubble_outline;
  //       bgColor = Colors.green.shade100;
  //       break;
  //     case "payment":
  //       icon = Icons.payment;
  //       bgColor = Colors.orange.shade100;
  //       break;
  //     default:
  //       icon = Icons.notifications;
  //       bgColor = Colors.grey.shade200;
  //   }

  //   return Container(
  //     height: 44,
  //     width: 44,
  //     decoration: BoxDecoration(
  //       color: bgColor,
  //       shape: BoxShape.circle,
  //     ),
  //     child: Icon(icon, size: 20),
  //   );
  // }

  Widget _typeIcon(ServiceNotification n) {
  final photo = n.senderPhoto;
  final name = n.senderName ?? "U";

  // ✅ If user photo exists → show profile avatar
  if (photo != null && photo.isNotEmpty) {
    return CircleAvatar(
      radius: 22,
      backgroundImage: NetworkImage(photo),
      backgroundColor: Colors.grey.shade200,
    );
  }

  // 🔁 Otherwise show type-based icon
  IconData icon;
  Color bgColor;

  switch (n.type) {
    case "booking":
      icon = Icons.calendar_today;
      bgColor = Colors.blue.shade100;
      break;
    case "chat":
      icon = Icons.chat_bubble_outline;
      bgColor = Colors.green.shade100;
      break;
    case "payment":
      icon = Icons.payment;
      bgColor = Colors.orange.shade100;
      break;
    default:
      icon = Icons.notifications;
      bgColor = Colors.grey.shade200;
  }

  return Container(
    height: 44,
    width: 44,
    decoration: BoxDecoration(
      color: bgColor,
      shape: BoxShape.circle,
    ),
    child: Icon(icon, size: 20),
  );
}

  //////////////////////////////////////////////////////////////
  /// NOTIFICATION CARD
  //////////////////////////////////////////////////////////////
  Widget _notificationCard(ServiceNotification n) {

    final primaryColor = Theme.of(context).colorScheme.primary;

    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _markRead(n.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.green.shade600,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.done, color: Colors.white),
            SizedBox(width: 6),
            Text(
              "Mark as read",
              style: TextStyle(color: Colors.white),
            )
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: n.isRead
              ? Colors.white
              : const Color(0xffEEF4FF),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openNotification(n),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _typeIcon(n),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      if (n.title != null && n.title!.isNotEmpty)
                        Text(
                          n.title!,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: n.isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                          ),
                        ),

                      if (n.senderName != null &&
                          n.senderName!.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 4),
                          child: Text(
                            n.senderName!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),

                      const SizedBox(height: 6),

                      Text(
                        n.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _formatTime(n.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                if (!n.isRead)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////////////
  /// UI
  //////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream(),
        builder: (_, snap) {

          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "You're all caught up!",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "We’ll notify you when something important happens.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final notifications = docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            return ServiceNotification.fromJson({
              ...data,
              "id": d.id,
            });
          }).toList();

          // 🔥 SORT: Unread first, then newest
          notifications.sort((a, b) {
            if (a.isRead != b.isRead) {
              return a.isRead ? 1 : -1;
            }

            try {
              final aDate = DateTime.parse(a.createdAt);
              final bDate = DateTime.parse(b.createdAt);
              return bDate.compareTo(aDate);
            } catch (_) {
              return 0;
            }
          });

          final unread =
              notifications.where((n) => !n.isRead).toList();
          final read =
              notifications.where((n) => n.isRead).toList();

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [

                if (unread.isNotEmpty) ...[
                  const Text(
                    "Unread",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...unread.map(_notificationCard),
                  const SizedBox(height: 20),
                ],

                if (read.isNotEmpty) ...[
                  const Text(
                    "Earlier",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...read.map(_notificationCard),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/chat_service.dart';
import '../../../services/session_manager.dart';
import 'chat_screen.dart';

class ProviderInboxScreen extends StatefulWidget {
  const ProviderInboxScreen({super.key});

  @override
  State<ProviderInboxScreen> createState() => _ProviderInboxScreenState();
}

class _ProviderInboxScreenState extends State<ProviderInboxScreen> {
  String? myUserId;

  final Set<String> _selectedChats = {};
  String _searchQuery = "";
  bool _selectionMode = false;

  //////////////////////////////////////////////////////////////
  /// INIT
  //////////////////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final id = await SessionManager.getServiceUserId();
    setState(() => myUserId = id);
  }

  //////////////////////////////////////////////////////////////
  /// FORMAT TIME
  //////////////////////////////////////////////////////////////

  String _formatTime(Timestamp? ts) {
    if (ts == null) return "";

    final dt = ts.toDate().toLocal();
    final now = DateTime.now();

    if (now.difference(dt).inDays == 0) {
      return TimeOfDay.fromDateTime(dt).format(context);
    }

    if (now.difference(dt).inDays == 1) {
      return "Yesterday";
    }

    return "${dt.day}/${dt.month}";
  }

  //////////////////////////////////////////////////////////////
  /// MARK ALL READ
  //////////////////////////////////////////////////////////////

  Future<void> _markAllRead(List<QueryDocumentSnapshot> docs) async {
    for (var doc in docs) {
      await doc.reference.update({"unread_count": 0});
    }
  }

  //////////////////////////////////////////////////////////////
  /// DELETE SELECTED
  //////////////////////////////////////////////////////////////

  Future<void> _deleteSelected() async {
    for (var id in _selectedChats) {
      await FirebaseFirestore.instance
          .collection("service_chats")
          .doc(id)
          .delete();
    }

    setState(() {
      _selectedChats.clear();
      _selectionMode = false;
    });
  }

  //////////////////////////////////////////////////////////////
  /// AVATAR
  //////////////////////////////////////////////////////////////

  Widget _avatar(String? photo, String name) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: const Color(0xffE3F2FD),
      backgroundImage:
          photo != null && photo.isNotEmpty ? NetworkImage(photo) : null,
      child: (photo == null || photo.isEmpty)
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : "U",
              style: const TextStyle(
                color: Color(0xff1976D2),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            )
          : null,
    );
  }

  //////////////////////////////////////////////////////////////
  /// CHAT ROW
  //////////////////////////////////////////////////////////////

  Widget _chatRow(QueryDocumentSnapshot chatDoc) {
    final data = chatDoc.data() as Map<String, dynamic>;

    final bookingId = data["booking_id"];

    ////////////////////////////////////////////////////////////
    /// FIXED NAME / PHOTO LOGIC
    ////////////////////////////////////////////////////////////

    final participants = List<String>.from(data["participants"] ?? []);

    final otherUserId =
        participants.firstWhere((id) => id != myUserId, orElse: () => "");

    final String name =
        data["user_${otherUserId}_name"] ??
        data["last_sender_name"] ??
        "User";

    final String? photo =
        data["user_${otherUserId}_photo"] ??
        data["last_sender_photo"];

    ////////////////////////////////////////////////////////////

    final String? lastSenderId = data["last_sender_id"];
    final String message = data["last_message"] ?? "";
    final Timestamp? ts = data["last_message_time"];

    final int unread = data["unread_count"] ?? 0;

    final bool iSentLast = lastSenderId == myUserId;

    final bool showUnreadBadge = !iSentLast && unread > 0;

    final bool highlight = showUnreadBadge;

    return InkWell(
      onTap: () async {
        if (showUnreadBadge) {
          await chatDoc.reference.update({"unread_count": 0});
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
  bookingId: bookingId,
  myUserId: myUserId!,
)
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xffE8F2FF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            _avatar(photo, name),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontWeight:
                                highlight ? FontWeight.bold : FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(ts),
                        style: TextStyle(
                          fontSize: 12,
                          color: highlight
                              ? const Color(0xff1F8DED)
                              : Colors.grey,
                          fontWeight:
                              highlight ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [

                      if (iSentLast)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            unread == 0
                                ? Icons.done_all
                                : Icons.done,
                            size: 18,
                            color: unread == 0
                                ? const Color(0xff1F8DED)
                                : Colors.grey,
                          ),
                        ),

                      Expanded(
                        child: Text(
                          message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                highlight ? FontWeight.bold : FontWeight.normal,
                            color:
                                highlight ? Colors.black : Colors.grey[700],
                          ),
                        ),
                      ),

                      if (showUnreadBadge)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xff1F8DED),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unread.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////////////
  /// BUILD
  //////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    if (myUserId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          "Inbox",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final snap =
                  await ChatService.streamChats(myUserId!).first;
              _markAllRead(snap.docs);
            },
            child: const Text("Mark all read"),
          ),
        ],
      ),
      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(14),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search conversations...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) =>
                  setState(() => _searchQuery = v),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ChatService.streamChats(myUserId!),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No conversations yet",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) =>
                      _chatRow(docs[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
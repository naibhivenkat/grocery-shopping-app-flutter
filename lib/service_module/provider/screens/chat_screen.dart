import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../services/chat_service.dart';
import '../../../services/session_manager.dart';

class ChatScreen extends StatefulWidget {
  final String bookingId;
  final String myUserId;

  const ChatScreen({
    super.key,
    required this.bookingId,
    required this.myUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String receiverId = "";
  String receiverName = "User";
  String receiverPhoto = "";

  bool initialScrollDone = false;

//////////////////////////////////////////////////////////////
// INIT
//////////////////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();
    _loadChatInfo();
  }

//////////////////////////////////////////////////////////////
// LOAD CHAT INFO
//////////////////////////////////////////////////////////////

Future<void> _loadChatInfo() async {

  if (widget.bookingId.isEmpty) return;

  final chatDoc = await FirebaseFirestore.instance
      .collection("service_chats")
      .doc(widget.bookingId)
      .get();

  if (!chatDoc.exists) return;

  final data = chatDoc.data();

  if (data == null) return;

  final List participants = data["participants"] ?? [];

  if (participants.length < 2) return;

  receiverId = participants.firstWhere(
    (id) => id != widget.myUserId,
    orElse: () => "",
  );

  //receiverName = data["last_sender_name"] ?? "User";
  //receiverPhoto = data["last_sender_photo"] ?? "";

  final lastSenderId = data["last_sender_id"];
final lastSenderName = data["last_sender_name"];
final lastSenderPhoto = data["last_sender_photo"];

if (lastSenderId == widget.myUserId) {
  // I sent last message → other person is receiver
  receiverName = "User";
  receiverPhoto = "";
} else {
  // Other person sent last message
  receiverName = lastSenderName ?? "User";
  receiverPhoto = lastSenderPhoto ?? "";
}

  await ChatService.markMessagesRead(
    bookingId: widget.bookingId,
    myUserId: widget.myUserId,
  );

  if (mounted) {
    setState(() {});
  }
}

//////////////////////////////////////////////////////////////
// SEND MESSAGE
//////////////////////////////////////////////////////////////

  Future<void> _send() async {

    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final myName = await SessionManager.getFullName();
    final myPhoto = await SessionManager.getPhotoBase64();

    String realReceiver = receiverId;

      if (realReceiver.isEmpty) {
        final chatDoc = await FirebaseFirestore.instance
            .collection("service_chats")
            .doc(widget.bookingId)
            .get();

        if (chatDoc.exists) {
          final participants = chatDoc.data()?["participants"] ?? [];
          realReceiver = participants.firstWhere(
            (id) => id != widget.myUserId,
            orElse: () => "",
          );
        }
      }

      await ChatService.sendMessage(
        chatId: widget.bookingId,
        senderId: widget.myUserId,
        receiverId: realReceiver,
        text: text,
        senderName: myName ?? "",
        senderPhoto: myPhoto ?? "",
      );

      // ----- --== //

    _msgController.clear();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

//////////////////////////////////////////////////////////////
// DATE DIVIDER
//////////////////////////////////////////////////////////////

  Widget _dateDivider(DateTime date) {

    final now = DateTime.now();

    String label;

    if (DateUtils.isSameDay(date, now)) {
      label = "Today";
    } else if (DateUtils.isSameDay(
        date, now.subtract(const Duration(days: 1)))) {
      label = "Yesterday";
    } else {
      label = DateFormat("dd MMM yyyy").format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

//////////////////////////////////////////////////////////////
// MESSAGE BUBBLE
//////////////////////////////////////////////////////////////

  Widget _bubble(Map<String, dynamic> msg) {

    final isMe = msg["sender_id"] == widget.myUserId;

    final timestamp = msg["created_at"] as Timestamp?;
    final time = timestamp != null
        ? DateFormat('hh:mm a').format(timestamp.toDate())
        : "";

    final isRead = msg["read"] ?? false;

    IconData tickIcon;
    Color tickColor;

    if (isRead) {
      tickIcon = Icons.done_all;
      tickColor = const Color(0xff34B7F1);
    } else if (isMe) {
      tickIcon = Icons.done_all;
      tickColor = Colors.grey.shade600;
    } else {
      tickIcon = Icons.done;
      tickColor = Colors.grey.shade600;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [

          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: CircleAvatar(
                radius: 15,
                backgroundImage: receiverPhoto.isNotEmpty
                    ? MemoryImage(base64Decode(receiverPhoto))
                    : null,
                child: receiverPhoto.isEmpty
                    ? const Icon(Icons.person, size: 16)
                    : null,
              ),
            ),

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? const Color(0xffDCF8C6)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 2,
                    color: Colors.black.withOpacity(.05),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [

                  Text(
                    msg["text"] ?? "",
                    style: const TextStyle(
                        fontSize: 15, color: Colors.black87),
                  ),

                  const SizedBox(height: 4),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      if (isMe) const SizedBox(width: 4),

                      if (isMe)
                        Icon(
                          tickIcon,
                          size: 17,
                          color: tickColor,
                        )
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

//////////////////////////////////////////////////////////////
// BUILD
//////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {

    if (widget.bookingId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Invalid chat")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffECE5DD),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [

            CircleAvatar(
              radius: 18,
              backgroundImage: receiverPhoto.isNotEmpty
                  ? MemoryImage(base64Decode(receiverPhoto))
                  : null,
              child: receiverPhoto.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),

            const SizedBox(width: 10),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(receiverName,
                    style: const TextStyle(
                        color: Colors.black, fontSize: 16)),

                receiverId.isEmpty
                    ? const SizedBox()
                    : StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection("user_presence")
                            .doc(receiverId)
                            .snapshots(),
                        builder: (_, snap) {

                          if (!snap.hasData || !snap.data!.exists) {
                            return const SizedBox();
                          }

                          final data =
                              snap.data!.data() as Map<String, dynamic>;

                          final online = data["online"] ?? false;

                          if (online) {
                            return const Text("Online",
                                style: TextStyle(
                                    fontSize: 11, color: Colors.green));
                          }

                          final lastSeen =
                              (data["last_seen"] as Timestamp?)?.toDate();

                          if (lastSeen == null) return const SizedBox();

                          final diff =
                              DateTime.now().difference(lastSeen);

                          return Text(
                            "Last seen ${diff.inMinutes}m ago",
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          );
                        },
                      )
              ],
            )
          ],
        ),
      ),

      body: Column(
        children: [

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.bookingId.isEmpty
                  ? null
                  : ChatService.streamMessages(widget.bookingId),
              builder: (_, snap) {

                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                      child: Text("Start conversation 👋"));
                }

                final msgs = docs
                    .map((e) => e.data() as Map<String, dynamic>)
                    .toList();

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!initialScrollDone) {
                    _scrollController.jumpTo(
                        _scrollController.position.maxScrollExtent);
                    initialScrollDone = true;
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {

                    final msg = msgs[i];

                    final timestamp =
                        msg["created_at"] as Timestamp?;
                    final msgDate = timestamp?.toDate();

                    bool showDate = false;

                    if (i == 0) {
                      showDate = true;
                    } else {

                      final prev =
                          msgs[i - 1]["created_at"] as Timestamp?;

                      if (prev != null &&
                          msgDate != null &&
                          !DateUtils.isSameDay(
                              prev.toDate(), msgDate)) {
                        showDate = true;
                      }
                    }

                    final bubble = _bubble(msg);

                    if (showDate && msgDate != null) {
                      return Column(
                        children: [
                          _dateDivider(msgDate),
                          bubble
                        ],
                      );
                    }

                    return bubble;
                  },
                );
              },
            ),
          ),

          widget.bookingId.isEmpty
              ? const SizedBox()
              : StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("typing_status")
                      .doc(widget.bookingId)
                      .snapshots(),
                  builder: (_, snap) {

                    if (!snap.hasData || !snap.data!.exists) {
                      return const SizedBox();
                    }

                    final data =
                        snap.data!.data() as Map<String, dynamic>;

                    final typingUser = data["typing_user"];

                    if (typingUser == receiverId) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text("Typing...",
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      );
                    }

                    return const SizedBox();
                  },
                ),

          Container(
            padding:
                const EdgeInsets.fromLTRB(12, 8, 12, 12),
            color: Colors.white,
            child: Row(
              children: [

                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _msgController,
                      onChanged: (text) {
                        ChatService.setTyping(
                            widget.bookingId,
                            widget.myUserId,
                            text.isNotEmpty);
                      },
                      decoration: const InputDecoration(
                          hintText: "Type a message...",
                          border: InputBorder.none),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                GestureDetector(
                  onTap: _send,
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xff128C7E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send,
                        color: Colors.white),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}


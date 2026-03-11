import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String chats = "service_chats";
  static const String messages = "messages";
  static const String notifications = "service_notifications";

  //////////////////////////////////////////////////////////////
  /// SEND MESSAGE (SAFE FIX)
  //////////////////////////////////////////////////////////////
  static Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
    String? senderName,
    String? senderPhoto,
  }) async {
    try {
      final chatRef = _db.collection(chats).doc(chatId);
      final msgRef = chatRef.collection(messages).doc();
      final notifRef =
          _db.collection(notifications).doc("${receiverId}_${chatId}_chat");

      final now = FieldValue.serverTimestamp();
      final batch = _db.batch();

      //////////////////////////////////////////////////////////////
      /// UPDATE CHAT DOC
      //////////////////////////////////////////////////////////////
      batch.set(chatRef, {
        "booking_id": chatId,
        //"participants": [senderId, receiverId],

        "participants": [
            senderId,
            if (receiverId.isNotEmpty) receiverId
          ],

        "last_message": text,
        "last_message_time": now,
        "updated_at": now,

        // 👇 ADD THESE (NEW SAFE FIELDS)
        "last_sender_id": senderId,
        "last_sender_name": senderName,
        "last_sender_photo": senderPhoto,

        "unread_count": FieldValue.increment(1),

      }, SetOptions(merge: true));

      //////////////////////////////////////////////////////////////
      /// SAVE MESSAGE
      //////////////////////////////////////////////////////////////
      batch.set(msgRef, {
        "id": msgRef.id,
        "sender_id": senderId,
        "receiver_id": receiverId,
        "text": text,
        "created_at": now,
        "read": false,
      });

      //////////////////////////////////////////////////////////////
      /// NOTIFICATIONS (UNCHANGED)
      //////////////////////////////////////////////////////////////
      final notifDoc = await notifRef.get();

      if (notifDoc.exists) {
        batch.update(notifRef, {
          "body": text,
          "is_read": false,
          "unread_count": FieldValue.increment(1),
          "created_at": now,
          "sender_id": senderId,
          "sender_name": senderName,
          "sender_photo": senderPhoto,
          "type": "chat",
          "data": {
            "booking_id": chatId,
            "type": "chat",
          }
        });
      } else {
        batch.set(notifRef, {
          "title": "New message",
          "body": text,
          "type": "chat",
          "provider_id": receiverId,
          "is_read": false,
          "created_at": now,
          "unread_count": 1,
          "sender_id": senderId,
          "sender_name": senderName,
          "sender_photo": senderPhoto,
          "data": {
            "booking_id": chatId,
            "type": "chat",
          }
        });
      }

      await batch.commit();
    } catch (e) {
      print("Chat send error: $e");
    }
  }

  //////////////////////////////////////////////////////////////
  /// STREAM CHAT LIST
  //////////////////////////////////////////////////////////////

static Stream<QuerySnapshot> streamChats(String userId) {
  return _db
      .collection(chats)
      .where("participants", arrayContains: userId)
      .orderBy("last_message_time", descending: true)
      .snapshots();
}
  //////////////////////////////////////////////////////////////
  /// STREAM MESSAGES
  //////////////////////////////////////////////////////////////
  static Stream<QuerySnapshot> streamMessages(String chatId) {
    return _db
        .collection(chats)
        .doc(chatId)
        .collection(messages)
        .orderBy("created_at")
        .snapshots();
  }

  //////////////////////////////////////////////////////////////
  /// MARK READ
  //////////////////////////////////////////////////////////////
  static Future<void> markMessagesRead({
    required String bookingId,
    required String myUserId,
  }) async {
    try {
      final chatRef = _db.collection(chats).doc(bookingId);

      final msgs = await chatRef
          .collection(messages)
          .where("receiver_id", isEqualTo: myUserId)
          .where("read", isEqualTo: false)
          .get();

      final batch = _db.batch();

      for (final d in msgs.docs) {
        batch.update(d.reference, {"read": true});
      }

      batch.update(chatRef, {"unread_count": 0});

      await batch.commit();
    } catch (e) {
      print("Mark read error: $e");
    }
  }

  //////////////////////////////////////////////////////////////
// TYPING STATUS
//////////////////////////////////////////////////////////////

static Future<void> setTyping(
    String chatId,
    String userId,
    bool typing) async {

  await _db
      .collection("typing_status")
      .doc(chatId)
      .set({
    "typing_user": typing ? userId : null
  }, SetOptions(merge: true));
}

//////////////////////////////////////////////////////////////
// USER PRESENCE
//////////////////////////////////////////////////////////////

static Future<void> updatePresence(
    String userId,
    bool online) async {

  await _db
      .collection("user_presence")
      .doc(userId)
      .set({
    "online": online,
    "last_seen": FieldValue.serverTimestamp()
  }, SetOptions(merge: true));
}
}
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import '../service_module/provider/screens/chat_screen.dart';
import 'session_manager.dart';


import '../main.dart';


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.high,
  );

  //////////////////////////////////////////////////////////////
  /// INITIALIZE
  //////////////////////////////////////////////////////////////
  static Future<void> initialize() async {
    try {
      await _firebaseMessaging.requestPermission();

      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      await _initLocalNotifications();

      /// FOREGROUND MESSAGE
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        await _showForegroundNotification(message);
      });

      /// CLICK HANDLER (APP IN BACKGROUND)
      FirebaseMessaging.onMessageOpenedApp
          .listen(_handleNotificationNavigation);

      /// TOKEN UPLOAD
      await checkAndUploadToken();
    } catch (e) {
      debugPrint("Notification init safe error: $e");
    }
  }

  //////////////////////////////////////////////////////////////
  /// LOCAL NOTIFICATION INIT
  //////////////////////////////////////////////////////////////
  static Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_notification');

    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // When foreground notification tapped
        if (details.payload != null) {
          final data = jsonDecode(details.payload!);
          _navigate(data);
        }
      },
    );

    if (!kIsWeb && Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }
  }

  //////////////////////////////////////////////////////////////
  /// FOREGROUND NOTIFICATION SHOW
  //////////////////////////////////////////////////////////////
  static Future<void> _showForegroundNotification(
      RemoteMessage message) async {

    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_notification',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data), // 🔥 important
    );
  }

  //////////////////////////////////////////////////////////////
  /// NAVIGATION HANDLER
  //////////////////////////////////////////////////////////////
  static void _handleNotificationNavigation(RemoteMessage message) {
    _navigate(message.data);
  }


  static void _navigate(Map<String, dynamic> data) {
  final type = data["type"];
  final bookingId = data["booking_id"];
  final userId = data["receiver_id"];

  if (type == "chat" && bookingId != null && userId != null) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          bookingId: bookingId,
          myUserId: userId,
        ),
      ),
    );
  }

  if (type == "booking" && bookingId != null) {
    navigatorKey.currentState?.pushNamed(
      "/booking-detail",
      arguments: bookingId,
    );
  }

  if (type == "payment") {
    navigatorKey.currentState?.pushNamed("/wallet");
  }
}

  //////////////////////////////////////////////////////////////
  /// TOKEN UPLOAD
  //////////////////////////////////////////////////////////////
  static Future<void> checkAndUploadToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token == null) return;

      String? role = await SessionManager.getRole();
      String? userId;

      if (role == "customer") {
        userId = await SessionManager.getCustomerId();
      } else if (role == "shopowner" || role == "shopkeeper") {
        userId = await SessionManager.getShopkeeperId();
      } else if (role == "provider") {
        userId = await SessionManager.getServiceUserId();
      }

      if (userId != null) {
        await _registerTokenOnServer(userId, role!, token);
      }
    } catch (e) {
      debugPrint("Token upload error: $e");
    }
  }

  static Future<void> _registerTokenOnServer(
      String userId, String role, String token) async {

    const baseUrl =
        "https://grocery-backend-956424262985.asia-south1.run.app";

    await http.post(
      Uri.parse('$baseUrl/service/api/register_fcm_token'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "role": role,
        "token": token,
      }),
    );
  }
}

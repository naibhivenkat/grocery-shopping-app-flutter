import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'session_manager.dart';

// ✅ Background Message Handler (Must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // ✅ Initialize Notifications
  static Future<void> initialize() async {
    // 1. Request Permission
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Set Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Setup Local Notifications (For Foreground display)
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_notification');


    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    
    await _localNotifications.initialize(initSettings);

    // 4. Create Channel for Android 8+
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 5. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_notification',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // 6. Check & Upload Token
    await checkAndUploadToken();
  }

  // ✅ MADE PUBLIC: Call this from Login Screen after saving session
  static Future<void> checkAndUploadToken() async {
    String? token = await _firebaseMessaging.getToken();
    if (token == null) return;

    print("FCM Token: $token");

    // Get User Details
    String? role = await SessionManager.getRole();
    String? userId;

    if (role == "customer") {
      userId = await SessionManager.getCustomerId();
    } else if (role == "shopowner" || role == "shopkeeper") {
      userId = await SessionManager.getShopkeeperId();
    }

    if (userId != null && role != null) {
      // Call Backend API to save token
      await _registerTokenOnServer(userId, role, token);
    }
  }

  static Future<void> _registerTokenOnServer(String userId, String role, String token) async {
    final String baseUrl = "https://grocery-backend-956424262985.asia-south1.run.app";
    try {
      await http.post(
        // ✅ FIXED URL: Added /api
        Uri.parse('$baseUrl/api/register_fcm_token'), 
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "role": role,
          "token": token
        }),
      );
      print("✅ FCM Token registered with backend");
    } catch (e) {
      print("❌ Failed to register FCM token: $e");
    }
  }
}
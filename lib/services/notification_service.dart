import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import 'session_manager.dart';

// ✅ Background Message Handler (Must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint("🔔 Background message: ${message.messageId}");
  } catch (e) {
    debugPrint("⚠️ Background handler Firebase init failed: $e");
  }
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ✅ Android Channel (only used on Android)
  static const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  // ✅ Initialize Notifications
  static Future<void> initialize() async {
    try {
      // ✅ 1) Request Permission (iOS will show permission popup)
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint("✅ Notification permission: ${settings.authorizationStatus}");

      // ✅ 2) Background Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // ✅ 3) Local Notifications init (Android + iOS)
      await _initLocalNotifications();

      // ✅ 4) Foreground Message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        await _showForegroundNotification(message);
      });

      // ✅ 5) Optional: When user taps notification and app opens
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint("📲 Notification clicked: ${message.messageId}");
        // You can navigate to some page here if needed
      });

      // ✅ 6) Token upload (safe)
      await checkAndUploadToken();
    } catch (e) {
      // ✅ Prevent app crash (especially iOS simulator)
      debugPrint("⚠️ Notification init skipped (safe): $e");
    }
  }

  // ✅ Local Notification Init
  static Future<void> _initLocalNotifications() async {
    // Android init
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_notification');

    // iOS init
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // ✅ Create Android notification channel only on Android
    if (!kIsWeb && Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }
  }

  // ✅ Foreground Notification
  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    try {
      final RemoteNotification? notification = message.notification;

      // If notification is null, skip
      if (notification == null) return;

      // Android details
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        icon: '@mipmap/ic_notification',
        importance: Importance.high,
        priority: Priority.high,
      );

      // iOS details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
      );
    } catch (e) {
      debugPrint("⚠️ Foreground notification show error: $e");
    }
  }

  // ✅ MADE PUBLIC: Call this from Login Screen after saving session
  static Future<void> checkAndUploadToken() async {
    try {
      // ✅ iOS Simulator note: APNS token may be null, FCM token may fail
      if (!kIsWeb && Platform.isIOS) {
        try {
          final apnsToken = await _firebaseMessaging.getAPNSToken();
          debugPrint("🍏 APNS Token (iOS): $apnsToken");
        } catch (e) {
          debugPrint("⚠️ APNS token not available (simulator): $e");
        }
      }

      String? token = await _firebaseMessaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint("⚠️ FCM token not available right now.");
        return;
      }

      debugPrint("✅ FCM Token: $token");

      // ✅ Get User Details
      String? role = await SessionManager.getRole();
      String? userId;

      if (role == "customer") {
        userId = await SessionManager.getCustomerId();
      } else if (role == "shopowner" || role == "shopkeeper") {
        userId = await SessionManager.getShopkeeperId();
      }

      if (userId != null && role != null && role.isNotEmpty) {
        await _registerTokenOnServer(userId, role, token);
      } else {
        debugPrint("⚠️ Token not sent: userId/role missing");
      }
    } catch (e) {
      debugPrint("⚠️ checkAndUploadToken error (safe): $e");
    }
  }

  static Future<void> _registerTokenOnServer(
      String userId, String role, String token) async {
    final String baseUrl =
        "https://grocery-backend-956424262985.asia-south1.run.app";

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/register_fcm_token'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "role": role,
          "token": token,
        }),
      );

      if (res.statusCode == 200) {
        debugPrint("✅ FCM Token registered with backend");
      } else {
        debugPrint("⚠️ Backend token register failed: ${res.statusCode} ${res.body}");
      }
    } catch (e) {
      debugPrint("❌ Failed to register FCM token: $e");
    }
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'service_module/provider/screens/chat_screen.dart';
import 'service_module/provider/screens/booking_detail_screen.dart';
import 'service_module/provider/screens/customer_booking_detail_screen.dart';
import 'service_module/provider/api/service_api.dart';

import 'services/notification_service.dart';
import 'services/session_manager.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/customer_home_screen.dart';
import 'screens/shop_owner_dashboard.dart';
import 'screens/shop_selection_screen.dart';
import 'screens/role_grid_screen.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await NotificationService.initialize();

  String langCode = await SessionManager.getLanguage();
  if (langCode.isEmpty) langCode = "en";

  runApp(MyApp(savedLocale: Locale(langCode)));
}

class MyApp extends StatefulWidget {
  final Locale savedLocale;

  const MyApp({super.key, required this.savedLocale});

  static void setLocale(BuildContext context, Locale newLocale) {
    final _MyAppState? state =
        context.findAncestorStateOfType<_MyAppState>();
    state?.changeLocale(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.savedLocale;
    _handleInitialNotification();
  }

  //////////////////////////////////////////////////////////////
  /// Handle push when app opened from killed state
  //////////////////////////////////////////////////////////////
  Future<void> _handleInitialNotification() async {
    RemoteMessage? message =
        await FirebaseMessaging.instance.getInitialMessage();

    if (message != null) {
      _navigateFromNotification(message);
    }
  }

  //////////////////////////////////////////////////////////////
  /// Push navigation handler
  //////////////////////////////////////////////////////////////
  void _navigateFromNotification(RemoteMessage message) {
    final data = message.data;

    final type = data["type"];
    final bookingId = data["booking_id"];
    final userId = data["receiver_id"];

    /// CHAT OPEN
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

    /// BOOKING OPEN
    if (type == "booking" && bookingId != null) {
      navigatorKey.currentState?.pushNamed(
        "/booking-detail",
        arguments: bookingId,
      );
    }

    /// PAYMENT OPEN
    if (type == "payment") {
      navigatorKey.currentState?.pushNamed("/wallet");
    }
  }

  //////////////////////////////////////////////////////////////
  /// Resolve booking screen based on ownership
  //////////////////////////////////////////////////////////////
  Future<Widget> _resolveBookingScreen(String bookingId) async {
    try {
      /// logged in user id
      final myUserId = await SessionManager.getServiceUserId();

      /// fetch booking
      final res = await ServiceApi.bookingDetail(bookingId);
      final booking = res["booking"];

      final providerId = booking["provider_id"];
      final requesterId = booking["requester_id"];

      /// 🟢 PROVIDER VIEW
      if (myUserId == providerId) {
        return BookingDetailScreen(
          bookingId: bookingId,
          providerId: myUserId!,
        );
      }

      /// 🔵 CUSTOMER / REQUESTER VIEW
      return CustomerBookingDetailScreen(
        bookingId: bookingId,
      );

    } catch (e) {
      return const Scaffold(
        body: Center(child: Text("Failed to load booking")),
      );
    }
  }

  void changeLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  //////////////////////////////////////////////////////////////
  /// APP UI
  //////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Grocery App',
      locale: _locale,
      supportedLocales: const [
        Locale("en"),
        Locale("kn"),
        Locale("hi"),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),

      home: const SplashScreen(),

      routes: {
        '/login': (context) => const LoginScreen(),
        '/role_select': (context) => const RoleGridScreen(),
        '/customer_home': (context) => const CustomerHomeScreen(),
        '/shop_owner_home': (context) => const ShopOwnerDashboardScreen(),
        '/shop_selection': (context) => const ShopSelectionScreen(),

        //////////////////////////////////////////////////////////////
        /// 🔥 BOOKING DETAIL ROUTE (FINAL FIX)
        //////////////////////////////////////////////////////////////
        '/booking-detail': (context) {
          final bookingId =
              ModalRoute.of(context)!.settings.arguments as String;

          return FutureBuilder<Widget>(
            future: _resolveBookingScreen(bookingId),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return snap.data!;
            },
          );
        },
      },
    );
  }
}
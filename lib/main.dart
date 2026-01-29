import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'services/notification_service.dart';
import 'services/session_manager.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/customer_home_screen.dart';
import 'screens/shop_owner_dashboard.dart';
import 'screens/shop_selection_screen.dart';

// ✅ NEW GRID ROLE SCREEN
import 'screens/role_grid_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String langCode = "en";

  try {
    await Firebase.initializeApp();
    debugPrint("✅ Firebase initialized successfully");
  } catch (e) {
    debugPrint("❌ Firebase init failed: $e");
  }

  try {
    await NotificationService.initialize();
    debugPrint("✅ NotificationService initialized successfully");
  } catch (e) {
    debugPrint("❌ Notification init failed: $e");
  }

  try {
    langCode = await SessionManager.getLanguage();
    if (langCode.isEmpty) langCode = "en";
    debugPrint("✅ Saved Language Loaded: $langCode");
  } catch (e) {
    debugPrint("❌ Language load failed: $e");
    langCode = "en";
  }

  runApp(MyApp(savedLocale: Locale(langCode)));
}

class MyApp extends StatefulWidget {
  final Locale savedLocale;
  const MyApp({super.key, required this.savedLocale});

  static void setLocale(BuildContext context, Locale newLocale) {
    final _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
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
  }

  void changeLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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

      // ✅ Always load Splash first
      home: const SplashScreen(),

      routes: {
        '/login': (context) => const LoginScreen(),

        // ✅ NEW (4 grid buttons screen)
        '/role_select': (context) => const RoleGridScreen(),

        '/customer_home': (context) => const CustomerHomeScreen(),
        '/shop_owner_home': (context) => const ShopOwnerDashboardScreen(),
        '/shop_selection': (context) => const ShopSelectionScreen(),
      },
    );
  }
}

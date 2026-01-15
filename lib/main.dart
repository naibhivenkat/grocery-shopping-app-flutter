// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart'; // ✅ Import Firebase Core
// import 'services/notification_service.dart'; // ✅ Import Notification Service
// import 'screens/splash_screen.dart';
// import 'screens/login_screen.dart';
// import 'screens/customer_home_screen.dart';
// import 'screens/shop_owner_dashboard.dart';
// import 'screens/shop_selection_screen.dart';

// // ✅ Change main to async
// void main() async {
//   // ✅ Ensure Flutter bindings are initialized
//   WidgetsFlutterBinding.ensureInitialized();

//   // ✅ Initialize Firebase
//   // Make sure you have added google-services.json to android/app/ folder
//   await Firebase.initializeApp();

//   // ✅ Initialize Notifications (FCM)
//   await NotificationService.initialize();

//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Grocery App',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
//         useMaterial3: true,
//       ),
//       initialRoute: '/',
//       routes: {
//         '/': (context) => const SplashScreen(),
//         '/login': (context) => const LoginScreen(),
//         '/customer_home': (context) => const CustomerHomeScreen(),
//         '/shop_owner_home': (context) => const ShopOwnerDashboardScreen(),
//         '/shop_selection': (context) => const ShopSelectionScreen(),
//       },
//     );
//   }
// }

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase
  await Firebase.initializeApp();

  // ✅ Initialize Notifications (FCM)
  await NotificationService.initialize();

  // ✅ Load saved language before app starts
  final langCode = await SessionManager.getLanguage(); // "en", "kn", "hi"

  runApp(MyApp(savedLocale: Locale(langCode)));
}

class MyApp extends StatefulWidget {
  final Locale savedLocale;

  const MyApp({super.key, required this.savedLocale});

  // ✅ Call this anywhere to update app language instantly
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

      // ✅ IMPORTANT: This is what applies the language
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

      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/customer_home': (context) => const CustomerHomeScreen(),
        '/shop_owner_home': (context) => const ShopOwnerDashboardScreen(),
        '/shop_selection': (context) => const ShopSelectionScreen(),
      },
    );
  }
}

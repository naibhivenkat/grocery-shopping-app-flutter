// import 'package:flutter/material.dart';
// import '../services/session_manager.dart';
// import 'login_screen.dart'; // To restart app flow
// import '../main.dart';


// class LanguageSelectionScreen extends StatefulWidget {
//   const LanguageSelectionScreen({super.key});

//   @override
//   State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
// }

// class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
//   String _currentLanguage = 'en';

//   final List<Map<String, String>> _languages = [
//     {'code': 'en', 'name': 'English', 'native': 'English'},
//     {'code': 'kn', 'name': 'Kannada', 'native': 'ಕನ್ನಡ'},
//     {'code': 'hi', 'name': 'Hindi', 'native': 'हिंदी'},
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _loadLanguage();
//   }

//   Future<void> _loadLanguage() async {
//     String lang = await SessionManager.getLanguage();
//     setState(() {
//       _currentLanguage = lang;
//     });
//   }

//   Future<void> _changeLanguage(String code) async {
//     await SessionManager.setLanguage(code);
//     setState(() {
//       _currentLanguage = code;
//     });

//     if (!mounted) return;

//     // Show confirmation
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Language Changed. Please restart the app for full effect.")),
//     );
    
//     // Optional: Restart App or Go to Splash
//     // Navigator.pushAndRemoveUntil(
//     //   context,
//     //   MaterialPageRoute(builder: (_) => const SplashScreen()),
//     //   (route) => false,
//     // );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Select Language"),
//         backgroundColor: Colors.green,
//         foregroundColor: Colors.white,
//       ),
//       body: ListView.separated(
//         itemCount: _languages.length,
//         separatorBuilder: (ctx, i) => const Divider(height: 1),
//         itemBuilder: (context, index) {
//           final lang = _languages[index];
//           final bool isSelected = lang['code'] == _currentLanguage;

//           return ListTile(
//             leading: CircleAvatar(
//               backgroundColor: isSelected ? Colors.green : Colors.grey.shade200,
//               child: Text(
//                 lang['code']!.toUpperCase(),
//                 style: TextStyle(
//                   color: isSelected ? Colors.white : Colors.black,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 14,
//                 ),
//               ),
//             ),
//             title: Text(lang['native']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             subtitle: Text(lang['name']!),
//             trailing: isSelected 
//                 ? const Icon(Icons.check_circle, color: Colors.green) 
//                 : null,
//             onTap: () => _changeLanguage(lang['code']!),
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../services/session_manager.dart';
import '../main.dart'; // ✅ Needed to call MyApp.setLocale()

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _currentLanguage = 'en';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'kn', 'name': 'Kannada', 'native': 'ಕನ್ನಡ'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिंदी'},
  ];

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    String lang = await SessionManager.getLanguage();
    if (!mounted) return;
    setState(() {
      _currentLanguage = lang;
    });
  }

  Future<void> _changeLanguage(String code) async {
    // ✅ Save in local storage
    await SessionManager.setLanguage(code);

    if (!mounted) return;

    // ✅ Apply instantly (no restart required)
    MyApp.setLocale(context, Locale(code));

    setState(() {
      _currentLanguage = code;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Language changed to ${code.toUpperCase()}")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Language"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        itemCount: _languages.length,
        separatorBuilder: (ctx, i) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final lang = _languages[index];
          final bool isSelected = lang['code'] == _currentLanguage;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isSelected ? Colors.green : Colors.grey.shade200,
              child: Text(
                lang['code']!.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            title: Text(
              lang['native']!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(lang['name']!),
            trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
            onTap: () => _changeLanguage(lang['code']!),
          );
        },
      ),
    );
  }
}

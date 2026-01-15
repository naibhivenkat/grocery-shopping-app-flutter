import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String keyIsLogin = 'isLoggedIn';
  static const String keyAuthToken = 'auth_token';
  static const String keyUsername = 'username';
  static const String keyRole = 'role';
  
  // User IDs
  static const String keyCustomerId = 'customer_id';
  static const String keyShopkeeperId = 'shopkeeper_id';
  static const String keyFirebaseId = 'firebase_id';
  
  // Shop Info
  static const String keyShopId = 'shop_id';
  static const String keyShopName = 'shop_name';
  static const String keyHasItemsAdded = 'has_items_added'; // ✅ New Key

  // Profile Keys
  static const String keyFullName = 'full_name';
  static const String keyPhone = 'phone';
  static const String keyAddress = 'address';

  // --- GET INSTANCE HELPER ---
  static Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  // --- AUTH TOKEN ---
  static Future<void> setAuthToken(String token) async {
    (await _prefs).setString(keyAuthToken, token);
  }

  static Future<String?> getAuthToken() async {
    return (await _prefs).getString(keyAuthToken);
  }

  // --- SAVE LOGIN DATA ---
  static Future<void> saveLogin(String username, String role) async {
    final p = await _prefs;
    p.setString(keyUsername, username);
    p.setString(keyRole, role);
    p.setBool(keyIsLogin, true);
  }

  // --- USER IDs ---
  static Future<void> setCustomerId(String id) async => (await _prefs).setString(keyCustomerId, id);
  static Future<String?> getCustomerId() async => (await _prefs).getString(keyCustomerId);

  static Future<void> setShopkeeperId(String id) async => (await _prefs).setString(keyShopkeeperId, id);
  static Future<String?> getShopkeeperId() async => (await _prefs).getString(keyShopkeeperId);

  static Future<void> setFirebaseId(String id) async => (await _prefs).setString(keyFirebaseId, id);

  // --- SHOP INFO ---
  static Future<void> setShopId(String id) async => (await _prefs).setString(keyShopId, id);
  static Future<String?> getShopId() async => (await _prefs).getString(keyShopId);

  static Future<void> setShopInfo(String id, String name) async {
    final p = await _prefs;
    p.setString(keyShopId, id);
    p.setString(keyShopName, name);
  }
  static Future<String?> getShopName() async => (await _prefs).getString(keyShopName);

  // ✅ ADDED: Has Items Added Logic
  static Future<void> setHasItemsAdded(bool hasItems) async {
    (await _prefs).setBool(keyHasItemsAdded, hasItems);
  }

  static Future<bool> hasShopWithItems() async {
    return (await _prefs).getBool(keyHasItemsAdded) ?? false;
  }

  // --- SAVE PROFILE ---
  static Future<void> saveUserProfile(String fullName, String address, String phone) async {
    final p = await _prefs;
    p.setString(keyFullName, fullName);
    p.setString(keyAddress, address);
    p.setString(keyPhone, phone);
  }

  // --- CHECK LOGIN ---
  static Future<bool> isLoggedIn() async {
    return (await _prefs).getBool(keyIsLogin) ?? false;
  }

  static Future<String?> getRole() async {
    return (await _prefs).getString(keyRole);
  }

  // --- LOGOUT ---
  static Future<void> logout() async {
    (await _prefs).clear(); 


  }

  // Add inside SessionManager class
static Future<String?> getUsername() async => (await _prefs).getString(keyUsername);


// Add inside SessionManager class
  static Future<String?> getFullName() async => (await _prefs).getString(keyFullName);
  static Future<String?> getEmail() async => (await _prefs).getString('email'); // Ensure key exists
  static Future<String?> getPhone() async => (await _prefs).getString(keyPhone);
  static Future<String?> getAddress() async => (await _prefs).getString(keyAddress);

  // Add these if missing inside SessionManager
  static Future<void> saveUserProfileFull(
      String name, String address, String phone, String email, String? photoBase64) async {
    final p = await _prefs;
    p.setString(keyFullName, name);
    p.setString(keyAddress, address);
    p.setString(keyPhone, phone);
    p.setString('email', email);
    if (photoBase64 != null) {
      p.setString('photo_base64', photoBase64);
    }
  }
  
  static Future<String?> getPhotoBase64() async => (await _prefs).getString('photo_base64');

  // --- LANGUAGE ---
  static const String keyLanguage = 'language_code'; // 'en', 'kn', 'hi'

  static Future<void> setLanguage(String code) async {
    (await _prefs).setString(keyLanguage, code);
  }

  static Future<String> getLanguage() async {
    return (await _prefs).getString(keyLanguage) ?? 'en'; // Default English
  }

  // --- RATING HELPERS ---
  static Future<bool> isOrderRated(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('rated_$orderId') ?? false;
  }

  static Future<void> markOrderRated(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rated_$orderId', true);
  }
}
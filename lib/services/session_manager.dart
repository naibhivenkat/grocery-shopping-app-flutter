import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  // LOGIN
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
  static const String keyHasItemsAdded = 'has_items_added';

  // ✅ Profile Keys (STANDARD)
  static const String keyFullName = 'fullName';
  static const String keyEmail = 'email';
  static const String keyPhone = 'phone';
  static const String keyAddress = 'address';
  static const String keyLocation = 'location';

  // ✅ Photo Keys (STANDARD)
  static const String keyPhotoUrl = 'photo_url';
  static const String keyPhotoBase64 = 'photo_base64';

  // --- GET INSTANCE HELPER ---
  static Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

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
    await p.setString(keyUsername, username);
    await p.setString(keyRole, role);
    await p.setBool(keyIsLogin, true);
  }

  // ✅ SAVE FULL PROFILE (Used in Login + Edit Profile)
  static Future<void> saveUserProfileFull({
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required String location,
    required String photoUrl,
    required String photoBase64,
  }) async {
    final p = await _prefs;
    await p.setString(keyFullName, fullName);
    await p.setString(keyEmail, email);
    await p.setString(keyPhone, phone);
    await p.setString(keyAddress, address);
    await p.setString(keyLocation, location);

    await p.setString(keyPhotoUrl, photoUrl);
    await p.setString(keyPhotoBase64, photoBase64);
  }

  // --- USER IDs ---
  static Future<void> setCustomerId(String id) async =>
      (await _prefs).setString(keyCustomerId, id);
  static Future<String?> getCustomerId() async =>
      (await _prefs).getString(keyCustomerId);

  static Future<void> setShopkeeperId(String id) async =>
      (await _prefs).setString(keyShopkeeperId, id);
  static Future<String?> getShopkeeperId() async =>
      (await _prefs).getString(keyShopkeeperId);

  static Future<void> setFirebaseId(String id) async =>
      (await _prefs).setString(keyFirebaseId, id);

  // --- SHOP INFO ---
  static Future<void> setShopId(String id) async =>
      (await _prefs).setString(keyShopId, id);
  static Future<String?> getShopId() async =>
      (await _prefs).getString(keyShopId);

  static Future<void> setShopInfo(String id, String name) async {
    final p = await _prefs;
    await p.setString(keyShopId, id);
    await p.setString(keyShopName, name);
  }

  static Future<String?> getShopName() async =>
      (await _prefs).getString(keyShopName);

  // --- Has Items Added ---
  static Future<void> setHasItemsAdded(bool hasItems) async {
    (await _prefs).setBool(keyHasItemsAdded, hasItems);
  }

  static Future<bool> hasShopWithItems() async {
    return (await _prefs).getBool(keyHasItemsAdded) ?? false;
  }

  // --- CHECK LOGIN ---
  static Future<bool> isLoggedIn() async {
    return (await _prefs).getBool(keyIsLogin) ?? false;
  }

  static Future<String?> getRole() async {
    return (await _prefs).getString(keyRole);
  }

  static Future<String?> getUsername() async =>
      (await _prefs).getString(keyUsername);

  // --- GET PROFILE ---
  static Future<String?> getFullName() async =>
      (await _prefs).getString(keyFullName);

  static Future<String?> getEmail() async =>
      (await _prefs).getString(keyEmail);

  static Future<String?> getPhone() async =>
      (await _prefs).getString(keyPhone);

  static Future<String?> getAddress() async =>
      (await _prefs).getString(keyAddress);

  static Future<String?> getLocation() async =>
      (await _prefs).getString(keyLocation);

  // --- PHOTO HELPERS ---
  static Future<void> savePhotoUrl(String url) async {
    final prefs = await _prefs;
    await prefs.setString(keyPhotoUrl, url);
  }

  static Future<String?> getPhotoUrl() async {
    final prefs = await _prefs;
    return prefs.getString(keyPhotoUrl);
  }

  static Future<void> savePhotoBase64(String base64) async {
    final prefs = await _prefs;
    await prefs.setString(keyPhotoBase64, base64);
  }

  static Future<String?> getPhotoBase64() async {
    final prefs = await _prefs;
    return prefs.getString(keyPhotoBase64);
  }

  // --- LOGOUT ---
  // static Future<void> logout() async {
  //   (await _prefs).clear();
  // }
  static Future<void> logout() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove("auth_token");
  await prefs.remove("role");
  await prefs.remove("username");
  await prefs.remove("firebaseId");
  await prefs.remove("shopkeeperId");
  await prefs.remove("customerId");
  await prefs.remove("shopId");
  await prefs.remove("shopName");
  await prefs.remove("hasItems");

  // ✅ optional: clear all
  await prefs.clear();
}


  // --- LANGUAGE ---
  static const String keyLanguage = 'language_code';

  static Future<void> setLanguage(String code) async {
    (await _prefs).setString(keyLanguage, code);
  }

  static Future<String> getLanguage() async {
    return (await _prefs).getString(keyLanguage) ?? 'en';
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

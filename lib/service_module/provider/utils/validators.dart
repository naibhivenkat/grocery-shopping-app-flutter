class Validators {
  static String? requiredField(String? v, {String label = "This field"}) {
    if (v == null || v.trim().isEmpty) return "$label is required";
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return "Email is required";
    final x = v.trim();
    final ok = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(x);
    if (!ok) return "Enter valid email";
    return null;
  }

  static String? mobile(String? v) {
    if (v == null || v.trim().isEmpty) return "Mobile number is required";
    final x = v.trim();
    if (!RegExp(r"^\d{10}$").hasMatch(x)) return "Enter 10-digit mobile number";
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return "Password is required";
    if (v.length < 6) return "Min 6 characters";
    return null;
  }
}

class LoginResponse {
  final bool? success;
  final String? message;
  final String? token;
  final User? user;

  LoginResponse({this.success, this.message, this.token, this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'],
      message: json['message'],
      token: json['token'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}

class User {
  final String? username;
  final String? role;
  final String? customerId;
  final String? shopkeeperId;
  final String? firebaseId;
  final String? fullName;
  final String? address;
  final String? phone;
  final String? email;
  final String? location;
  final String? photoBase64;
  // We will add Shop info later when we need it
  
  User({
    this.username,
    this.role,
    this.customerId,
    this.shopkeeperId,
    this.firebaseId,
    this.fullName,
    this.address,
    this.phone,
    this.email,
    this.location,
    this.photoBase64,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'],
      role: json['role'],
      // JSON might return integers for IDs, so we safely convert to String
      customerId: json['customer_id']?.toString(),
      shopkeeperId: json['shopkeeper_id']?.toString(),
      firebaseId: json['firebase_id']?.toString(),
      fullName: json['full_name'],
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      location: json['location'],
      photoBase64: json['photoBase64'],
    );
  }
}
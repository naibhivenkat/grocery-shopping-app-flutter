class Shop {
  final String id;
  final String name;
  final String address;
  final String contact;

  Shop({
    required this.id,
    required this.name,
    required this.address,
    required this.contact,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      // Ensure we handle both String and Int IDs safely
      id: json['id'].toString(),
      name: json['name'] ?? "Unknown Shop",
      address: json['address'] ?? "",
      contact: json['contact'] ?? "",
    );
  }
}
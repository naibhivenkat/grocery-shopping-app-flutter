class Item {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final String shopId;

  Item({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.shopId,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'].toString(),
      name: json['name'],
      description: json['description'],
      // Safely convert price to double even if API sends string/int
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      // API sends 'image' but your model asked for imageUrl. We map it here.
      imageUrl: json['image'], 
      shopId: json['shopId'].toString(),
    );
  }
}
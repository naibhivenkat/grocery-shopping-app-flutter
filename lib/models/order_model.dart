class OrderItem {
  final String itemId;
  final String name;
  
  // ✅ FIX: Removed 'final' so Shop Owner can edit price
  double price; 
  
  double quantity; // Mutable for editing
  double originalQuantity; // For refund calc
  String? comment;
  final String? imageUrl;

  OrderItem({
    required this.itemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.originalQuantity,
    this.comment,
    this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      itemId: json['item_id'] ?? "",
      name: json['name'] ?? "Unknown",
      
      // Safe parsing for numbers
      price: double.parse((json['price'] ?? 0).toString()),
      quantity: double.parse((json['quantity'] ?? 0).toString()),
      
      // Default original to current if missing
      originalQuantity: double.parse((json['original_quantity'] ?? json['quantity'] ?? 0).toString()),
      
      comment: json['comment'],
      imageUrl: json['image'],
    );
  }

  // Matches Kotlin Payload for Update
  Map<String, dynamic> toJson() => {
    "item_id": itemId,
    "quantity": quantity,
    "price": price,
    "comment": comment ?? ""
  };
}
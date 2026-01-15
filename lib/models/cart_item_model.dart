import 'item_model.dart';

class CartItem {
  final Item item;
  double quantity;
  String unit; // "KG", "Grams", "Pcs"

  CartItem({
    required this.item,
    required this.quantity,
    required this.unit,
  });
}
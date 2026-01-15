import '../models/item_model.dart';
import '../models/cart_item_model.dart';

class CartManager {
  // Singleton pattern
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  // Storage: Map<ShopID, List<CartItem>>
  final Map<String, List<CartItem>> _carts = {};

  // Add Item
  void addToCart(Item item, String shopId, double quantity, String unit) {
    if (!_carts.containsKey(shopId)) {
      _carts[shopId] = [];
    }

    final shopCart = _carts[shopId]!;
    
    // Check if item already exists with the SAME UNIT
    final existingIndex = shopCart.indexWhere((element) => 
        element.item.id == item.id && element.unit == unit);

    if (existingIndex != -1) {
      // Update existing
      shopCart[existingIndex].quantity += quantity;
    } else {
      // Add new
      shopCart.add(CartItem(item: item, quantity: quantity, unit: unit));
    }
  }

  // Get Cart Items
  List<CartItem> getCart(String shopId) {
    return _carts[shopId] ?? [];
  }

  // Remove Item
  void removeFromCart(String shopId, CartItem cartItem) {
    if (_carts.containsKey(shopId)) {
      _carts[shopId]!.remove(cartItem);
    }
  }

  // Update Quantity directly
  void updateQuantity(String shopId, CartItem cartItem, double newQty) {
    cartItem.quantity = newQty;
  }

  // --- ⚡ PRICE CALCULATION LOGIC ---
  double calculateItemTotal(CartItem item) {
    if (item.unit == "Grams") {
      // If unit is Grams, assume price is per KG.
      // Formula: (Price / 1000) * Grams
      return (item.item.price / 1000.0) * item.quantity;
    } 
    // For KG and Pcs, it's just Price * Qty
    return item.item.price * item.quantity;
  }

  // Calculate Grand Total using the new logic
  double getTotal(String shopId) {
    if (!_carts.containsKey(shopId)) return 0.0;
    return _carts[shopId]!.fold(0.0, (sum, cartItem) => sum + calculateItemTotal(cartItem));
  }
  
  // Clear Cart
  void clearCart(String shopId) {
    _carts.remove(shopId);
  }
}
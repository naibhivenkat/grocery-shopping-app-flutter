import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../services/cart_manager.dart';
import 'order_confirm_screen.dart'; 

class CartScreen extends StatefulWidget {
  final String shopId;
  final String shopName;

  const CartScreen({super.key, required this.shopId, required this.shopName});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _cartItems = [];
  
  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  void _loadCart() {
    setState(() {
      _cartItems = CartManager().getCart(widget.shopId);
    });
  }

  void _updateQuantity(CartItem cartItem, double change) {
    setState(() {
      double newQty = cartItem.quantity + change;
      if (newQty < 1 && cartItem.unit != "Grams") {
        // Only remove if it hits 0 (unless it's grams, where we might want steps of 50g or 100g)
        // For simplicity: Remove if < 1 for now (or < 50 for grams if you want)
         CartManager().removeFromCart(widget.shopId, cartItem);
         _loadCart();
      } else if (newQty <= 0) {
         CartManager().removeFromCart(widget.shopId, cartItem);
         _loadCart();
      } else {
        CartManager().updateQuantity(widget.shopId, cartItem, newQty);
      }
    });
  }

  // --- IMAGE HELPER ---
  Widget _buildItemImage(String? url) {
    if (url == null || url.isEmpty) return const Icon(Icons.image, color: Colors.grey);
    if (url.startsWith('http')) {
      return Image.network(url, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image));
    }
    return Image.asset("assets/$url", fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image, color: Colors.red));
  }

  // --- CONFIRM DIALOG ---
  void _showConfirmDialog() {
    double total = CartManager().getTotal(widget.shopId);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Order"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Shop: ${widget.shopName}", style: const TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              // Use the new calculation for the summary
              ..._cartItems.map((c) {
                 double itemTotal = CartManager().calculateItemTotal(c);
                 return Text("${c.item.name} (${c.quantity} ${c.unit}) = ₹${itemTotal.toStringAsFixed(2)}");
              }),
              const Divider(),
              Text("Total: ₹${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); 
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (_) => OrderConfirmScreen(
                    shopId: widget.shopId,
                    total: total,
                    cartItems: _cartItems
                  )
                )
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Proceed", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    double grandTotal = CartManager().getTotal(widget.shopId);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Cart"),
        backgroundColor: Colors.green,
      ),
      body: _cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 10),
                  const Text("Your cart is empty", style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Go Back to Shop"),
                  )
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) {
                      final cartItem = _cartItems[index];
                      // ✅ Calculate individual price
                      double linePrice = CartManager().calculateItemTotal(cartItem);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 60, height: 60,
                                child: _buildItemImage(cartItem.item.imageUrl),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(cartItem.item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    // Display the calculated price
                                    Text("₹${linePrice.toStringAsFixed(2)}  (${cartItem.quantity} ${cartItem.unit})", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                    // Adjust step size for Grams (e.g., -50g) or others (-1)
                                    onPressed: () => _updateQuantity(cartItem, cartItem.unit == "Grams" ? -50 : -1),
                                  ),
                                  Text(
                                    cartItem.quantity.toStringAsFixed(0), 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                    // Adjust step size for Grams (e.g., +50g) or others (+1)
                                    onPressed: () => _updateQuantity(cartItem, cartItem.unit == "Grams" ? 50 : 1),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.1))]
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text("₹${grandTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _showConfirmDialog,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text("Confirm Order", style: TextStyle(fontSize: 18, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
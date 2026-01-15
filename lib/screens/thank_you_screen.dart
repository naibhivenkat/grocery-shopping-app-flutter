import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // Optional: Add lottie package for animation
import 'dart:async';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import 'customer_home_screen.dart';

class ThankYouScreen extends StatefulWidget {
  final String orderId;
  final String shopId;

  const ThankYouScreen({super.key, required this.orderId, required this.shopId});

  @override
  State<ThankYouScreen> createState() => _ThankYouScreenState();
}

class _ThankYouScreenState extends State<ThankYouScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Show Rating Bottom Sheet after 1.2 seconds
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) _showRatingBottomSheet();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showRatingBottomSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => RatingBottomSheet(orderId: widget.orderId, shopId: widget.shopId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success Animation (or Icon)
            Lottie.asset(
              'assets/lottie/success.json', // Add a lottie file or use Icon below
              width: 200,
              repeat: false,
              errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.check_circle, color: Colors.green, size: 100),
            ),
            const SizedBox(height: 20),
            const Text("Thank You!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Your order has been placed successfully 🎉", style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 40),
            
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
              ),
              child: const Text("Back to Home", style: TextStyle(color: Colors.white, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ⭐ RATING BOTTOM SHEET WIDGET
// ==========================================
class RatingBottomSheet extends StatefulWidget {
  final String orderId;
  final String shopId;

  const RatingBottomSheet({super.key, required this.orderId, required this.shopId});

  @override
  State<RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends State<RatingBottomSheet> {
  double _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _emojis = [
    {"label": "Bad", "emoji": "😡", "rating": 1.0},
    {"label": "Average", "emoji": "😐", "rating": 3.0},
    {"label": "Good", "emoji": "🙂", "rating": 4.0},
    {"label": "Excellent", "emoji": "😍", "rating": 5.0},
  ];

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a reaction 😄")));
      return;
    }

    setState(() => _isSubmitting = true);

    final customerId = await SessionManager.getCustomerId();
    final customerName = await SessionManager.getUsername() ?? "Customer";

    if (customerId != null) {
      // Find emoji char from rating
      final selectedEmoji = _emojis.firstWhere((e) => e['rating'] == _rating)['emoji'];

      await ApiService.rateShop({
        "order_id": widget.orderId,
        "shop_id": widget.shopId,
        "customer_id": customerId,
        "customer_name": customerName,
        "rating": _rating,
        "review": _reviewController.text.trim(),
        "emoji": selectedEmoji
      });
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context); // Close BottomSheet
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20, 
        left: 20, 
        right: 20, 
        top: 20
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Rate your experience", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Emoji Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _emojis.map((e) {
              bool isSelected = _rating == e['rating'];
              return GestureDetector(
                onTap: () => setState(() => _rating = e['rating']),
                child: AnimatedScale(
                  scale: isSelected ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    children: [
                      Text(e['emoji'], style: const TextStyle(fontSize: 40)),
                      if (isSelected) 
                        Text(e['label'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue))
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Review Box
          TextField(
            controller: _reviewController,
            decoration: InputDecoration(
              hintText: "Write a review (optional)...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.grey[100]
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 20),

          // Buttons
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Skip", style: TextStyle(color: Colors.grey)),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRating,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  child: _isSubmitting 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text("Submit", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
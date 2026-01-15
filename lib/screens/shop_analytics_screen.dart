import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import 'package:intl/intl.dart';

class ShopAnalyticsScreen extends StatefulWidget {
  const ShopAnalyticsScreen({super.key});

  @override
  State<ShopAnalyticsScreen> createState() => _ShopAnalyticsScreenState();
}

class _ShopAnalyticsScreenState extends State<ShopAnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _analyticsData;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    final shopId = await SessionManager.getShopId();
    if (shopId != null) {
      final data = await ApiService.getShopRatingAnalytics(shopId);
      if (mounted) {
        setState(() {
          _analyticsData = data;
          _isLoading = false;
        });
      }
    }
  }

  void _showReviewsBottomSheet(int rating, String emojiTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows full height
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => ReviewsBottomSheet(rating: rating, title: emojiTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_analyticsData == null) {
      return const Scaffold(body: Center(child: Text("Failed to load analytics")));
    }

    final double avgRating = double.tryParse(_analyticsData!['average_rating'].toString()) ?? 0.0;
    final int totalRatings = int.tryParse(_analyticsData!['total_ratings'].toString()) ?? 0;
    final Map<String, dynamic> breakdown = _analyticsData!['emoji_breakdown'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text("Shop Analytics"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // HEADER: Average Rating
            const Text("Average Rating", style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 5),
            Text("⭐ ${avgRating.toStringAsFixed(1)}", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            Text("$totalRatings ratings", style: const TextStyle(color: Colors.grey, fontSize: 14)),
            
            const SizedBox(height: 40),

            // EMOJI BREAKDOWN ROWS
            _buildEmojiRow("😍", "Excellent", 5, breakdown["😍"] ?? 0, totalRatings),
            _buildEmojiRow("🙂", "Good", 4, breakdown["🙂"] ?? 0, totalRatings),
            _buildEmojiRow("😐", "Average", 3, breakdown["😐"] ?? 0, totalRatings),
            _buildEmojiRow("😡", "Bad", 1, breakdown["😡"] ?? 0, totalRatings),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiRow(String emoji, String label, int rating, int count, int total) {
    double progress = total == 0 ? 0 : (count / total);

    return InkWell(
      onTap: () => _showReviewsBottomSheet(rating, "$emoji $label Reviews"),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("$count", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      color: _getColorForRating(rating),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Color _getColorForRating(int rating) {
    if (rating == 5) return Colors.purple;
    if (rating == 4) return Colors.green;
    if (rating == 3) return Colors.orange;
    return Colors.red;
  }
}

// ==========================================
// ⭐ REDESIGNED REVIEWS BOTTOM SHEET
// ==========================================
class ReviewsBottomSheet extends StatefulWidget {
  final int rating;
  final String title;

  const ReviewsBottomSheet({super.key, required this.rating, required this.title});

  @override
  State<ReviewsBottomSheet> createState() => _ReviewsBottomSheetState();
}

class _ReviewsBottomSheetState extends State<ReviewsBottomSheet> {
  List<dynamic> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final shopId = await SessionManager.getShopId();
    if (shopId != null) {
      final data = await ApiService.getShopReviewsByRating(shopId, widget.rating);
      if (mounted) {
        setState(() {
          _reviews = data;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75, 
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle Bar
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          
          // Title
          Text(widget.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator()) 
              : _reviews.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.comment_bank_outlined, size: 50, color: Colors.grey[300]),
                          const SizedBox(height: 10),
                          const Text("No reviews yet.", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _reviews.length,
                      itemBuilder: (ctx, i) {
                        final r = _reviews[i];
                        final String customerName = r['customer_name'] ?? 'Customer';
                        final String reviewText = (r['review'] ?? "").toString();
                        
                        // Parse Date
                        String dateStr = "";
                        try {
                           final dt = DateTime.parse(r['created_at']);
                           dateStr = DateFormat("dd MMM yyyy").format(dt);
                        } catch(e) { dateStr = "Recent"; }

                        // Generate Avatar Color based on name
                        Color avatarColor = Colors.primaries[customerName.length % Colors.primaries.length].shade100;
                        Color textColor = Colors.primaries[customerName.length % Colors.primaries.length].shade900;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200)
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Avatar
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: avatarColor,
                                    child: Text(
                                      customerName.isNotEmpty ? customerName[0].toUpperCase() : "?",
                                      style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  
                                  // Name & Date
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          customerName, 
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                        ),
                                        Text(
                                          dateStr, 
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12)
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Emoji Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade200)
                                    ),
                                    child: Text(r['emoji'] ?? "⭐", style: const TextStyle(fontSize: 16)),
                                  )
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Review Text
                              if (reviewText.isNotEmpty)
                                Text(
                                  reviewText,
                                  style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
                                )
                              else
                                const Text(
                                  "No written comment provided.",
                                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
          )
        ],
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/service_api.dart';
import '../screens/availability_calendar_screen.dart';
import '../utils/provider_theme.dart';
import '../utils/ui_helpers.dart';
import 'package:grocery_app_new_flutter/services/session_manager.dart';

class RequestServiceList extends StatefulWidget {
  final String categoryId;

  const RequestServiceList({super.key, required this.categoryId});

  @override
  State<RequestServiceList> createState() => _RequestServiceListState();
}

class _RequestServiceListState extends State<RequestServiceList> {
  bool _loading = true;
  List<dynamic> _providers = [];

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  /// LOAD SERVICES
  Future<void> _loadProviders() async {
    try {
     
      final requesterId = await SessionManager.getServiceUserId();

      final res =
          await ServiceApi.getAvailableServicesByCategory(widget.categoryId);

      /// 🚫 DOUBLE SAFETY — BLOCK OWN SERVICES
      final filtered =
          res.where((p) => p["provider_id"].toString() != requesterId).toList();

      /// ⭐ SMART SORT
      filtered.sort((a, b) {
        if ((a["available_today"] ?? false) !=
            (b["available_today"] ?? false)) {
          return (a["available_today"] ?? false) ? -1 : 1;
        }
        return (b["rating"] ?? 0).compareTo(a["rating"] ?? 0);
      });

      setState(() => _providers = filtered);
    } catch (e) {
      UIHelpers.showSnack(context, e.toString(), error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  /// PRICE FORMATTER
  String priceText(dynamic p) {
    final fixed = p["fixed_price"];
    final min = p["min_price"];
    final unit = p["pricing_unit"] ?? "fixed";

    String unitText = "";
    if (unit == "per_hour") unitText = "/hr";
    if (unit == "per_day") unitText = "/day";

    if (fixed != null && fixed != 0) {
      return "₹$fixed $unitText";
    }

    if (min != null) {
      return "Starts ₹$min $unitText";
    }

    return "Price on request";
  }

  /// SHORT ADDRESS
  String shortAddress(String? addr) {
    if (addr == null || addr.isEmpty) return "";
    if (addr.length > 28) return "${addr.substring(0, 28)}...";
    return addr;
  }

  /// OPEN CALENDAR BOOKING
  // void openCalendar(dynamic p) async {
  
  //  final requesterId = await SessionManager.getServiceUserId();


  //   /// 🚫 BLOCK SELF BOOKING
  //   if (p["provider_id"].toString() == requesterId) {
  //     UIHelpers.showSnack(
  //       context,
  //       "You cannot book your own service",
  //       error: true,
  //     );
  //     return;
  //   }

  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (_) => AvailabilityCalendarScreen(
  //         providerId: p["provider_id"],
  //         serviceName: p["service_name"] ?? "Service",
  //         serviceId: p["id"],
  //         bookingMode: true,
  //       ),
  //     ),
  //   );
  // }


void openCalendar(dynamic p) async {

  final requesterId = await SessionManager.getServiceUserId();

  /// 🚫 BLOCK SELF BOOKING
  if (p["provider_id"]?.toString() == requesterId) {
    UIHelpers.showSnack(
      context,
      "You cannot book your own service",
      error: true,
    );
    return;
  }

  /// 🔥 SAFE FIELD MAPPING
  final providerId = p["provider_id"]?.toString();
  final serviceId =
      p["service_id"]?.toString() ??
      p["id"]?.toString();   // fallback for old API

  if (providerId == null || providerId.isEmpty) {
    UIHelpers.showSnack(context, "Provider missing", error: true);
    return;
  }

  if (serviceId == null || serviceId.isEmpty) {
    UIHelpers.showSnack(context, "Service missing", error: true);
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AvailabilityCalendarScreen(
        providerId: providerId,
        serviceName: p["service_name"] ?? "Service",
        serviceId: serviceId,
        bookingMode: true,
      ),
    ),
  );
}
  /// PROVIDER CARD
  Widget providerCard(dynamic p) {
    final photo = p["photo_base64"];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                /// PROFILE IMAGE
                CircleAvatar(
                  radius: 30,
                  backgroundImage: photo != null &&
                          photo.toString().isNotEmpty
                      ? MemoryImage(base64Decode(photo))
                      : null,
                  child: photo == null ? const Icon(Icons.person) : null,
                ),

                const SizedBox(width: 12),

                /// DETAILS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// NAME + VERIFIED
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p["provider_name"] ?? "Provider",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (p["verified"] == true)
                            const Icon(Icons.verified,
                                color: Colors.green, size: 18)
                        ],
                      ),

                      const SizedBox(height: 4),

                      /// LOCATION
                      Text(
                        shortAddress(p["location"]),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 6),

                      /// RATING + JOBS
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.orange, size: 16),
                          if (p["rating"] != null)
                          Text("${p["rating"]}"),

                          const SizedBox(width: 8),
                          Text(
                            "${p["completed_jobs"] ?? 0} jobs",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// PRICE + AVAILABILITY
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  priceText(p),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (p["available_today"] == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Available today",
                      style: TextStyle(color: Colors.green),
                    ),
                  )
              ],
            ),

            const SizedBox(height: 12),

            /// BOOK BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => openCalendar(p),
                child: const Text("Book Now"),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ProviderTheme.themeData(),
      child: Scaffold(
        appBar: AppBar(title: const Text("Available Providers")),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _providers.isEmpty
                ? const Center(child: Text("No providers available"))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _providers.length,
                    itemBuilder: (_, i) => providerCard(_providers[i]),
                  ),
      ),
    );
  }
}


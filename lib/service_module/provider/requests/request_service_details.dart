// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:grocery_app_new_flutter/services/session_manager.dart';
// import '../api/service_api.dart';
// import '../utils/provider_theme.dart';
// import '../utils/ui_helpers.dart';
// import '../utils/service_catalog.dart';

// class RequestServiceDetails extends StatefulWidget {
//   final dynamic service;

//   const RequestServiceDetails({super.key, required this.service});

//   @override
//   State<RequestServiceDetails> createState() => _RequestServiceDetailsState();
// }

// class _RequestServiceDetailsState extends State<RequestServiceDetails> {
//   bool _loading = true;
//   List<dynamic> _providers = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadProviders();
//   }

//   Future<void> _loadProviders() async {
//     try {
//       final res = await ServiceApi.getAvailableServicesByCategory(
//         widget.service["service_category_id"] ?? widget.service["id"],
//       );

//       setState(() => _providers = res);
//     } catch (e) {
//       UIHelpers.showSnack(context, e.toString(), error: true);
//     } finally {
//       setState(() => _loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final title = widget.service["title"] ?? "Service";
//     final cat = ServiceCatalog.byId(
//         widget.service["service_category_id"] ?? widget.service["id"]);

//     return Theme(
//       data: ProviderTheme.themeData(),
//       child: Scaffold(
//         appBar: AppBar(title: Text(title)),
//         body: _loading
//             ? const Center(child: CircularProgressIndicator())
//             : ListView.builder(
//                 padding: const EdgeInsets.all(14),
//                 itemCount: _providers.length,
//                 itemBuilder: (_, i) {
//                   final p = _providers[i];
//                   final photo = p["photo_base64"];
//                   final price = p["fixed_price"] ?? 0;
//                   final minPrice = p["min_price"];
//                   final unit = p["pricing_unit"] ?? "fixed";

//                   return Card(
//                     margin: const EdgeInsets.only(bottom: 14),
//                     child: Padding(
//                       padding: const EdgeInsets.all(14),
//                       child: Column(
//                         children: [
//                           Row(
//                             children: [
//                               /// 🔥 SERVICE ICON
//                               Container(
//                                 height: 46,
//                                 width: 46,
//                                 decoration: BoxDecoration(
//                                   color: (cat?.color ??
//                                           ProviderTheme.primary)
//                                       .withOpacity(0.15),
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Icon(
//                                   cat?.icon ?? Icons.design_services,
//                                   color:
//                                       cat?.color ?? ProviderTheme.primary,
//                                 ),
//                               ),

//                               const SizedBox(width: 10),

//                               /// 🔥 PHOTO
//                               CircleAvatar(
//                                 radius: 26,
//                                 backgroundImage: photo != null &&
//                                         photo.toString().isNotEmpty
//                                     ? MemoryImage(base64Decode(photo))
//                                     : null,
//                                 child: photo == null
//                                     ? const Icon(Icons.person)
//                                     : null,
//                               ),

//                               const SizedBox(width: 12),

//                               /// NAME + LOCATION
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment:
//                                       CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       p["provider_name"] ?? "Provider",
//                                       style: const TextStyle(
//                                           fontWeight: FontWeight.w800,
//                                           fontSize: 16),
//                                     ),
//                                     if (p["location"] != null)
//                                       Text(
//                                         p["location"],
//                                         style: const TextStyle(
//                                             color: Colors.black54),
//                                       ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),

//                           const SizedBox(height: 14),

//                           /// PRICE
//                           Row(
//                             mainAxisAlignment:
//                                 MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 "₹$price ${unit == "per_hour" ? "/hr" : unit == "per_day" ? "/day" : ""}",
//                                 style: const TextStyle(
//                                     fontWeight: FontWeight.w700,
//                                     fontSize: 15),
//                               ),
//                               if (minPrice != null)
//                                 Text("Min ₹$minPrice",
//                                     style: const TextStyle(fontSize: 12)),
//                             ],
//                           ),

//                           const SizedBox(height: 10),

//                           /// BUTTONS
//                           Row(
//                             children: [
//                               OutlinedButton.icon(
//                                 icon: const Icon(Icons.schedule),
//                                 label: const Text("Slots"),
//                                 onPressed: () async {
//                                   final today = DateTime.now()
//                                       .toString()
//                                       .split(" ")[0];

//                                   final res =
//                                       await ServiceApi.getAvailability(
//                                     p["provider_id"],
//                                     today,
//                                   );

//                                   UIHelpers.showSnack(
//                                       context, "Slots loaded");
//                                   debugPrint(res.toString());
//                                 },
//                               ),
//                               const Spacer(),
//                               ElevatedButton(
//                                 child: const Text("Book"),
//                                 onPressed: () async {
//                                await ServiceApi.bookService({
//                                 "service_id": p["id"],
//                                 "provider_id": p["provider_id"],
//                                 "requester_id": SessionManager.getServiceRequesterId(), // logged in customer
//                                 "slot_date": DateTime.now().toString().split(" ")[0],
//                                 "slot_time": "10:00" // temporary until slot UI built
//                               });


//                                   UIHelpers.showSnack(
//                                       context, "Booking sent");
//                                 },
//                               )
//                             ],
//                           )
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//       ),
//     );
//   }
// }




import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:grocery_app_new_flutter/services/session_manager.dart';
import '../api/service_api.dart';
import '../utils/provider_theme.dart';
import '../utils/ui_helpers.dart';
import '../utils/service_catalog.dart';

class RequestServiceDetails extends StatefulWidget {
  final dynamic service;

  const RequestServiceDetails({super.key, required this.service});

  @override
  State<RequestServiceDetails> createState() => _RequestServiceDetailsState();
}

class _RequestServiceDetailsState extends State<RequestServiceDetails> {
  bool _loading = true;
  List<dynamic> _providers = [];

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    try {
      final res = await ServiceApi.getAvailableServicesByCategory(
        widget.service["service_category_id"] ?? widget.service["id"],
      );

      setState(() => _providers = res);
    } catch (e) {
      UIHelpers.showSnack(context, e.toString(), error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.service["title"] ?? "Service";
    final cat = ServiceCatalog.byId(
        widget.service["service_category_id"] ?? widget.service["id"]);

    return Theme(
      data: ProviderTheme.themeData(),
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: _providers.length,
                itemBuilder: (_, i) {
                  final p = _providers[i];
                  final photo = p["photo_base64"];
                  final price = p["fixed_price"] ?? 0;
                  final minPrice = p["minimum_charge"];
                  final pricingType = p["pricing_type"] ?? "fixed";

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              /// SERVICE ICON
                              Container(
                                height: 46,
                                width: 46,
                                decoration: BoxDecoration(
                                  color: (cat?.color ?? ProviderTheme.primary)
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  cat?.icon ?? Icons.design_services,
                                  color: cat?.color ?? ProviderTheme.primary,
                                ),
                              ),

                              const SizedBox(width: 10),

                              /// PHOTO
                              CircleAvatar(
                                radius: 26,
                                backgroundImage: photo != null &&
                                        photo.toString().isNotEmpty
                                    ? MemoryImage(base64Decode(photo))
                                    : null,
                                child: photo == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),

                              const SizedBox(width: 12),

                              /// NAME + LOCATION
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p["provider_name"] ?? "Provider",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16),
                                    ),
                                    if (p["location"] != null)
                                      Text(
                                        p["location"],
                                        style: const TextStyle(
                                            color: Colors.black54),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          /// PRICE LABEL
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _priceLabel(p),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15),
                              ),
                              if (minPrice != null)
                                Text("Min ₹$minPrice",
                                    style: const TextStyle(fontSize: 12)),
                            ],
                          ),

                          const SizedBox(height: 10),

                          /// BUTTONS
                          Row(
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.schedule),
                                label: const Text("Slots"),
                                onPressed: () async {
                                  final today = DateTime.now()
                                      .toString()
                                      .split(" ")[0];

                                  /// ✅ FIXED ROUTE
                                  final res =
                                      await ServiceApi.getAvailability(
                                    p["provider_id"],
                                    today,
                                  );

                                  UIHelpers.showSnack(
                                      context, "Slots loaded");
                                  debugPrint(res.toString());
                                },
                              ),
                              const Spacer(),
                              ElevatedButton(
                                child: const Text("Book"),
                                onPressed: () async {
                                  try {
                                    /// ✅ SAFE BOOK FLOW (OLD)
                                    await ServiceApi.bookService({
                                      "service_id": p["id"],
                                      "provider_id": p["provider_id"],
                                      "requester_id": SessionManager
                                          .getServiceRequesterId(),
                                      "slot_date": DateTime.now()
                                          .toString()
                                          .split(" ")[0],
                                      "slot_time": "10:00",
                                      "duration": 60
                                    });

                                    UIHelpers.showSnack(
                                        context, "Booking sent");
                                  } catch (e) {
                                    UIHelpers.showSnack(
                                        context, e.toString(),
                                        error: true);
                                  }
                                },
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  /// PRICE LABEL HANDLER
  String _priceLabel(dynamic p) {
    final type = p["pricing_type"];

    if (type == "hourly") {
      return "₹${p["hourly_price"] ?? 0}/hr";
    }

    if (type == "per_30") {
      return "₹${p["per_30min_price"] ?? 0}/30m";
    }

    if (type == "visit") {
      return "Visit ₹${p["inspection_charge"] ?? 0}";
    }

    if (type == "hybrid") {
      return "₹${p["inspection_charge"] ?? 0} + ₹${p["hourly_price"] ?? 0}/hr";
    }

    return "₹${p["fixed_price"] ?? 0}";
  }
}


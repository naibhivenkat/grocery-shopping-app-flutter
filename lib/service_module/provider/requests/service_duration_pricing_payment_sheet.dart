// import 'package:flutter/material.dart';
// import '../api/service_api.dart';
// import '../../../services/session_manager.dart';
// import '../utils/ui_helpers.dart';
// import '../../../managers/payment_manager.dart';

// class ServiceDurationPricingSheet extends StatefulWidget {
//   final String providerId;
//   final String serviceId;
//   final String slotDate;
//   final String slotTime;
//   final Map serviceData;

//   const ServiceDurationPricingSheet({
//     super.key,
//     required this.providerId,
//     required this.serviceId,
//     required this.slotDate,
//     required this.slotTime,
//     required this.serviceData,
//   });

//   @override
//   State<ServiceDurationPricingSheet> createState() =>
//       _ServiceDurationPricingSheetState();
// }

// class _ServiceDurationPricingSheetState
//     extends State<ServiceDurationPricingSheet> {

//   int hours = 1;
//   int minutes = 0;

//   double totalPrice = 0;

//   bool loadingPrice = false;
//   bool paying = false;

//   late PaymentManager paymentManager;

//   @override
//   void initState() {
//     super.initState();

//     /// ⭐ Razorpay manager init
//     paymentManager = PaymentManager(
//       onError: (msg) {
//         UIHelpers.showSnack(context, msg, error: true);
//       },
//       onPaymentVerified: (backendOrderId) async {
//           String? requesterId = await SessionManager.getServiceRequesterId();

//         requesterId ??= await SessionManager.getServiceUserId();

//         if (requesterId == null) {
//           UIHelpers.showSnack(context, "User not logged in", error: true);
//           return;
//         }

//         await _confirmBooking(requesterId);
//       },
//     );

//     _calculatePrice();
//   }

//   @override
//   void dispose() {
//     paymentManager.dispose();
//     super.dispose();
//   }

//   int get durationMinutes => (hours * 60) + minutes;

//   // ───────────────── PRICE CALCULATION ─────────────────

//   Future<void> _calculatePrice() async {
//     setState(() => loadingPrice = true);

//     try {
//       final res = await ServiceApi.calculateServicePrice({
//         "service_id": widget.serviceId,
//         "duration": durationMinutes,
//       });

//       setState(() => totalPrice = res["total_cost"].toDouble());
//     } catch (e) {
//       UIHelpers.showSnack(context, e.toString(), error: true);
//     } finally {
//       setState(() => loadingPrice = false);
//     }
//   }

//   // ───────────────── WALLET PAYMENT ─────────────────

//   Future<void> _payWithWallet() async {
//     setState(() => paying = true);

//           try {
//             String? requesterId = await SessionManager.getServiceRequesterId();

//       requesterId ??= await SessionManager.getServiceUserId();

//       if (requesterId == null) {
//         UIHelpers.showSnack(context, "User not logged in", error: true);
//         return;
//       }


//       final wallet = await ServiceApi.servicegetWalletBalance(requesterId);

//       if (wallet["balance"] < totalPrice) {
//         UIHelpers.showSnack(context, "Insufficient wallet balance", error: true);
//         setState(() => paying = false);
//         return;
//       }

//       // deduct wallet
//       await ServiceApi.servicedeductWallet({
//         "user_id": requesterId,
//         "amount": totalPrice,
//         "type": "service_booking",
//       });

//       await _confirmBooking(requesterId);

//     } catch (e) {
//       UIHelpers.showSnack(context, e.toString(), error: true);
//     }

//     setState(() => paying = false);
//   }

//   // ───────────────── RAZORPAY PAYMENT ─────────────────

//   Future<void> _payWithRazorpay() async {
//     try {
//       final res = await ServiceApi.createRazorpayOrder({
//         "amount": totalPrice,
//         "service_id": widget.serviceId,
//       });

//       paymentManager.startRazorpayCheckout(
//         shopName: "Service Booking",
//         totalAmount: totalPrice,
//         razorpayOrderId: res["razorpay_order_id"],
//         backendOrderId: res["backend_order_id"],
//       );

//     } catch (e) {
//       UIHelpers.showSnack(context, e.toString(), error: true);
//     }
//   }

//   // ───────────────── FINAL BOOKING ─────────────────

//   Future<void> _confirmBooking(String requesterId) async {
//     try {
//       await ServiceApi.bookService({
//         "service_id": widget.serviceId,
//         "provider_id": widget.providerId,
//         "requester_id": requesterId,
//         "slot_date": widget.slotDate,
//         "slot_time": widget.slotTime,
//         "duration": durationMinutes,
//       });

//       UIHelpers.showSnack(context, "Booking confirmed");
//       Navigator.pop(context);

//     } catch (e) {
//       UIHelpers.showSnack(context, e.toString(), error: true);
//     }
//   }

//   // ───────────────── UI ─────────────────

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [

//           const Text(
//             "Select Duration",
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),

//           const SizedBox(height: 16),

//           Row(
//             children: [
//               Expanded(
//                 child: DropdownButton<int>(
//                   value: hours,
//                   items: List.generate(8, (i) => i + 1)
//                       .map((e) => DropdownMenuItem(
//                             value: e,
//                             child: Text("$e hr"),
//                           ))
//                       .toList(),
//                   onChanged: (v) {
//                     setState(() => hours = v!);
//                     _calculatePrice();
//                   },
//                 ),
//               ),

//               Expanded(
//                 child: DropdownButton<int>(
//                   value: minutes,
//                   items: const [
//                     DropdownMenuItem(value: 0, child: Text("0 min")),
//                     DropdownMenuItem(value: 30, child: Text("30 min")),
//                   ],
//                   onChanged: (v) {
//                     setState(() => minutes = v!);
//                     _calculatePrice();
//                   },
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 16),

//           loadingPrice
//               ? const CircularProgressIndicator()
//               : Text(
//                   "Total: ₹$totalPrice",
//                   style: const TextStyle(
//                       fontSize: 20, fontWeight: FontWeight.bold),
//                 ),

//           const SizedBox(height: 20),

//           ElevatedButton(
//             onPressed: paying ? null : _payWithWallet,
//             child: const Text("Pay with Wallet"),
//           ),

//           const SizedBox(height: 10),

//           ElevatedButton(
//             onPressed: _payWithRazorpay,
//             child: const Text("Pay with Razorpay"),
//           ),
//         ],
//       ),
//     );
//   }
// }

// import 'dart:async';
// import 'package:flutter/material.dart';
// import '../api/service_api.dart';
// import '../../../services/session_manager.dart';
// import '../utils/ui_helpers.dart';
// import '../../../managers/payment_manager.dart';

// class ServiceDurationPricingSheet extends StatefulWidget {
//   final String providerId;
//   final String serviceId;
//   final String slotDate;
//   final String slotTime;
//   final Map serviceData;

//   const ServiceDurationPricingSheet({
//     super.key,
//     required this.providerId,
//     required this.serviceId,
//     required this.slotDate,
//     required this.slotTime,
//     required this.serviceData,
//   });

//   @override
//   State<ServiceDurationPricingSheet> createState() =>
//       _ServiceDurationPricingSheetState();
// }

// class _ServiceDurationPricingSheetState
//     extends State<ServiceDurationPricingSheet> {

//   int hours = 1;
//   int minutes = 0;

//   double serviceCost = 0;
//   double platformFee = 0;
//   double tax = 0;
//   double totalPrice = 0;

//   bool loadingPrice = false;
//   bool payingWallet = false;
//   bool payingOnline = false;

//   String? couponCode;
//   String? pendingBookingId;

//   Timer? debounce;

//   late PaymentManager paymentManager;

//   @override
//   void initState() {
//     super.initState();

//     paymentManager = PaymentManager(
//       onError: (msg) {
//         if (!mounted) return;
//         UIHelpers.showSnack(context, msg, error: true);
//         setState(() => payingOnline = false);
//       },
//       onPaymentVerified: (backendOrderId) async {
//         await _verifyAndConfirmBooking();
//       },
//     );

//     _calculatePrice();
//   }

//   @override
//   void dispose() {
//     paymentManager.dispose();
//     debounce?.cancel();
//     super.dispose();
//   }

//   int get durationMinutes => (hours * 60) + minutes;

//   // ───────────────── PRICE CALCULATION (DEBOUNCED) ─────────────────

//   void _calculatePrice() {
//     debounce?.cancel();
//     debounce = Timer(const Duration(milliseconds: 400), () async {
//       setState(() => loadingPrice = true);

//       try {
//         final res = await ServiceApi.calculateServicePrice({
//           "service_id": widget.serviceId,
//           "duration": durationMinutes,
//           "coupon": couponCode,
//         });

//         if (!mounted) return;

//         setState(() {
//           serviceCost = res["service_cost"].toDouble();
//           platformFee = res["platform_fee"].toDouble();
//           tax = res["tax"].toDouble();
//           totalPrice = res["total_cost"].toDouble();
//         });

//       } catch (e) {
//         if (!mounted) return;
//         UIHelpers.showSnack(context, "Price fetch failed", error: true);
//       } finally {
//         if (mounted) setState(() => loadingPrice = false);
//       }
//     });
//   }

//   // ───────────────── CREATE PENDING BOOKING ─────────────────

//   Future<String?> _createPendingBooking(String requesterId) async {
//     try {
//       final res = await ServiceApi.createPendingBooking({
//         "service_id": widget.serviceId,
//         "provider_id": widget.providerId,
//         "requester_id": requesterId,
//         "slot_date": widget.slotDate,
//         "slot_time": widget.slotTime,
//         "duration": durationMinutes,
//         "amount": totalPrice,
//       });

//       return res["booking_id"];

//     } catch (e) {
//       UIHelpers.showSnack(context, "Failed to initiate booking", error: true);
//       return null;
//     }
//   }

//   // ───────────────── WALLET PAYMENT ─────────────────

//   Future<void> _payWithWallet() async {
//     setState(() => payingWallet = true);

//     try {
//       String? requesterId = await SessionManager.getServiceRequesterId();
//       requesterId ??= await SessionManager.getServiceUserId();

//       if (requesterId == null) {
//         UIHelpers.showSnack(context, "User not logged in", error: true);
//         return;
//       }

//       pendingBookingId = await _createPendingBooking(requesterId);
//       if (pendingBookingId == null) return;

//       final wallet = await ServiceApi.servicegetWalletBalance(requesterId);

//       if (wallet["balance"] < totalPrice) {
//         UIHelpers.showSnack(context, "Insufficient wallet balance", error: true);
//         return;
//       }

//       await ServiceApi.servicedeductWallet({
//         "user_id": requesterId,
//         "amount": totalPrice,
//         "booking_id": pendingBookingId,
//       });

//       await _verifyAndConfirmBooking();

//     } catch (e) {
//       UIHelpers.showSnack(context, "Wallet payment failed", error: true);
//     }

//     setState(() => payingWallet = false);
//   }

//   // ───────────────── RAZORPAY PAYMENT ─────────────────

//   Future<void> _payWithRazorpay() async {
//     setState(() => payingOnline = true);

//     try {
//       String? requesterId = await SessionManager.getServiceRequesterId();
//       requesterId ??= await SessionManager.getServiceUserId();

//       if (requesterId == null) {
//         UIHelpers.showSnack(context, "User not logged in", error: true);
//         return;
//       }

//       pendingBookingId = await _createPendingBooking(requesterId);
//       if (pendingBookingId == null) return;

//       final res = await ServiceApi.createRazorpayOrder({
//         "amount": totalPrice,
//         "booking_id": pendingBookingId,
//       });

//       paymentManager.startRazorpayCheckout(
//         shopName: "Service Booking",
//         totalAmount: totalPrice,
//         razorpayOrderId: res["razorpay_order_id"],
//         backendOrderId: res["backend_order_id"],
//       );

//     } catch (e) {
//       UIHelpers.showSnack(context, "Online payment failed", error: true);
//       setState(() => payingOnline = false);
//     }
//   }

//   // ───────────────── VERIFY + CONFIRM BOOKING ─────────────────

//   Future<void> _verifyAndConfirmBooking() async {
//     try {
//       await ServiceApi.confirmBooking({
//         "booking_id": pendingBookingId,
//       });

//       if (!mounted) return;

//       UIHelpers.showSnack(context, "Booking confirmed 🎉");
//       Navigator.pop(context);

//     } catch (e) {
//       UIHelpers.showSnack(context, "Booking confirmation failed", error: true);
//     } finally {
//       if (mounted) setState(() => payingOnline = false);
//     }
//   }

//   // ───────────────── APPLY COUPON ─────────────────

//   void _applyCoupon() async {
//     final code = await UIHelpers.showInputDialog(context, "Enter coupon");

//     if (code == null || code.isEmpty) return;

//     setState(() => couponCode = code);
//     _calculatePrice();
//   }

//   // ───────────────── UI ─────────────────

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [

//           /// SERVICE SUMMARY
//           Align(
//             alignment: Alignment.centerLeft,
//             child: Text(
//               widget.serviceData["name"] ?? "Service",
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//           ),

//           Text("${widget.slotDate} • ${widget.slotTime}"),

//           const SizedBox(height: 20),

//           /// DURATION SELECTOR
//           Row(
//             children: [
//               Expanded(
//                 child: DropdownButton<int>(
//                   value: hours,
//                   items: List.generate(8, (i) => i + 1)
//                       .map((e) => DropdownMenuItem(value: e, child: Text("$e hr")))
//                       .toList(),
//                   onChanged: (v) {
//                     setState(() => hours = v!);
//                     _calculatePrice();
//                   },
//                 ),
//               ),
//               Expanded(
//                 child: DropdownButton<int>(
//                   value: minutes,
//                   items: const [
//                     DropdownMenuItem(value: 0, child: Text("0 min")),
//                     DropdownMenuItem(value: 30, child: Text("30 min")),
//                   ],
//                   onChanged: (v) {
//                     setState(() => minutes = v!);
//                     _calculatePrice();
//                   },
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 16),

//           /// PRICE BREAKDOWN
//           loadingPrice
//               ? const CircularProgressIndicator()
//               : Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _priceRow("Service", serviceCost),
//                     _priceRow("Platform fee", platformFee),
//                     _priceRow("Tax", tax),
//                     const Divider(),
//                     _priceRow("Total", totalPrice, bold: true),
//                   ],
//                 ),

//           const SizedBox(height: 10),

//           /// COUPON
//           TextButton(
//             onPressed: _applyCoupon,
//             child: const Text("Apply Coupon"),
//           ),

//           const SizedBox(height: 16),

//           /// WALLET PAYMENT
//           ElevatedButton(
//             onPressed: payingWallet ? null : _payWithWallet,
//             child: payingWallet
//                 ? const CircularProgressIndicator(color: Colors.white)
//                 : const Text("Pay with Wallet"),
//           ),

//           const SizedBox(height: 10),

//           /// ONLINE PAYMENT
//           ElevatedButton(
//             onPressed: payingOnline ? null : _payWithRazorpay,
//             child: payingOnline
//                 ? const CircularProgressIndicator(color: Colors.white)
//                 : const Text("Pay Online"),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _priceRow(String label, double amount, {bool bold = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label,
//               style: TextStyle(
//                   fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
//           Text("₹${amount.toStringAsFixed(0)}",
//               style: TextStyle(
//                   fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
//         ],
//       ),
//     );
//   }
// }


import 'dart:async';
import 'package:flutter/material.dart';
import '../api/service_api.dart';
import '../../../services/session_manager.dart';
import '../utils/ui_helpers.dart';
import '../../../managers/service_payment_manager.dart';



class ServiceDurationPricingSheet extends StatefulWidget {
  final String providerId;
  final String serviceId;
  final String slotDate;
  final String slotTime;
  final Map serviceData;

  const ServiceDurationPricingSheet({
    super.key,
    required this.providerId,
    required this.serviceId,
    required this.slotDate,
    required this.slotTime,
    required this.serviceData,
  });

  @override
  State<ServiceDurationPricingSheet> createState() =>
      _ServiceDurationPricingSheetState();
}

class _ServiceDurationPricingSheetState
    extends State<ServiceDurationPricingSheet> {

  int hours = 1;
  int minutes = 0;

  double serviceCost = 0;
  double platformFee = 0;
  double tax = 0;
  double totalPrice = 0;

  String pricingType = "fixed"; // ⭐ dynamic pricing type
  double visitCharge = 0;

  bool loadingPrice = false;
  bool payingWallet = false;
  bool payingOnline = false;

  String? couponCode;
  String? pendingBookingId;

  Timer? debounce;

  late ServicePaymentManager paymentManager;

  @override
  void initState() {
    super.initState();

    paymentManager = ServicePaymentManager(
      onError: (msg) {
        if (!mounted) return;
        UIHelpers.showSnack(context, msg, error: true);
        setState(() => payingOnline = false);
      },
      onPaymentVerified: (backendOrderId) async {
        await _verifyAndConfirmBooking();
      },
    );

    _calculatePrice();
  }

  @override
  void dispose() {
    paymentManager.dispose();
    debounce?.cancel();
    super.dispose();
  }

  int get durationMinutes => (hours * 60) + minutes;

  // ───────────────── PRICE CALCULATION ─────────────────

  void _calculatePrice() {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => loadingPrice = true);

      try {
        final res = await ServiceApi.calculateServicePrice({
          "service_id": widget.serviceId,
          "duration": durationMinutes,
          "coupon": couponCode,
        });

        if (!mounted) return;

        setState(() {
          pricingType = res["pricing_type"] ?? "fixed";
          visitCharge = (res["visit_charge"] ?? 0).toDouble();

          serviceCost = res["service_cost"].toDouble();
          platformFee = res["platform_fee"].toDouble();
          tax = res["tax"].toDouble();
          totalPrice = res["total_cost"].toDouble();
        });

      } catch (e) {
        if (!mounted) return;
        UIHelpers.showSnack(context, "Price fetch failed", error: true);
      } finally {
        if (mounted) setState(() => loadingPrice = false);
      }
    });
  }

  // ───────────────── CREATE PENDING BOOKING ─────────────────

Future<String?> _createPendingBooking(String requesterId) async {
  try {
    final res = await ServiceApi.createPendingBooking({
      "service_id": widget.serviceId,
      "provider_id": widget.providerId,
      "requester_id": requesterId,
      "slot_date": widget.slotDate,
      "slot_time": widget.slotTime,
      "duration": durationMinutes,
      "amount": totalPrice,
    });

    return res["booking_id"];

  } catch (e) {

    // ⭐ SHOW REAL BACKEND ERROR
    UIHelpers.showSnack(
      context,
      e.toString().replaceAll("Exception:", ""),
      error: true,
    );

    return null;
  }
}


  // ───────────────── WALLET PAYMENT ─────────────────

  Future<void> _payWithWallet() async {
    setState(() => payingWallet = true);

    try {
      String? requesterId = await SessionManager.getServiceRequesterId();
      requesterId ??= await SessionManager.getServiceUserId();

      if (requesterId == null) {
        UIHelpers.showSnack(context, "User not logged in", error: true);
        return;
      }

    if (widget.providerId == requesterId) {
  UIHelpers.showSnack(context, "You cannot book your own service", error: true);
  setState(() => payingWallet = false);
  return;
}

      pendingBookingId = await _createPendingBooking(requesterId);
      if (pendingBookingId == null) {
        setState(() => payingWallet = false);
        return;
      }


      final wallet = await ServiceApi.servicegetWalletBalance(requesterId);

      if (wallet["balance"] < totalPrice) {
        UIHelpers.showSnack(context, "Insufficient wallet balance", error: true);
        return;
      }

      await ServiceApi.servicedeductWallet({
        "user_id": requesterId,
        "amount": totalPrice,
        "booking_id": pendingBookingId,
      });

      await _verifyAndConfirmBooking();

    } catch (e) {
      UIHelpers.showSnack(context, "Wallet payment failed", error: true);
    }

    setState(() => payingWallet = false);
  }

  // ───────────────── RAZORPAY PAYMENT ─────────────────

  Future<void> _payWithRazorpay() async {
    setState(() => payingOnline = true);

    try {
      String? requesterId = await SessionManager.getServiceRequesterId();
      requesterId ??= await SessionManager.getServiceUserId();

      if (requesterId == null) {
        UIHelpers.showSnack(context, "User not logged in", error: true);
        return;
      }
     if (widget.providerId == requesterId) {
        UIHelpers.showSnack(context, "You cannot book your own service", error: true);
        setState(() => payingOnline = false);
        return;
      }


      pendingBookingId = await _createPendingBooking(requesterId);
    if (pendingBookingId == null) {
  setState(() => payingOnline = false); 
  return;
}



      final res = await ServiceApi.createRazorpayOrder({
        "amount": totalPrice,
        "booking_id": pendingBookingId,
      });

      paymentManager.startRazorpayCheckout(
        shopName: "Service Booking",
        totalAmount: totalPrice,
        razorpayOrderId: res["razorpay_order_id"],
        backendOrderId: res["backend_order_id"],
      );

    } catch (e) {
      UIHelpers.showSnack(context, "Online payment failed", error: true);
      setState(() => payingOnline = false);
    }
  }

  // ───────────────── VERIFY + CONFIRM BOOKING ─────────────────

  Future<void> _verifyAndConfirmBooking() async {
    try {
      await ServiceApi.confirmBooking({
        "booking_id": pendingBookingId,
      });

      if (!mounted) return;

      UIHelpers.showSnack(context, "Booking confirmed 🎉");
      Navigator.pop(context);

    } catch (e) {
      UIHelpers.showSnack(context, "Booking confirmation failed", error: true);
    } finally {
  if (mounted) {
    setState(() {
      payingOnline = false;
      payingWallet = false;
    });
  }
}

  }

  // ───────────────── APPLY COUPON ─────────────────

  void _applyCoupon() async {
    final code = await UIHelpers.showInputDialog(context, "Enter coupon");

    if (code == null || code.isEmpty) return;

    setState(() => couponCode = code);
    _calculatePrice();
  }

  // ───────────────── DURATION SELECTOR ─────────────────

  Widget _buildDurationSelector() {
    if (pricingType == "fixed" || pricingType == "visit") {
      return const SizedBox(); // hide for fixed/visit services
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Duration",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: DropdownButton<int>(
                value: hours,
                items: List.generate(8, (i) => i + 1)
                    .map((e) => DropdownMenuItem(value: e, child: Text("$e hr")))
                    .toList(),
                onChanged: (v) {
                  setState(() => hours = v!);
                  _calculatePrice();
                },
              ),
            ),

            if (pricingType != "hourly")
              Expanded(
                child: DropdownButton<int>(
                  value: minutes,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text("0 min")),
                    DropdownMenuItem(value: 30, child: Text("30 min")),
                  ],
                  onChanged: (v) {
                    setState(() => minutes = v!);
                    _calculatePrice();
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.serviceData["name"] ?? "Service",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          Text("${widget.slotDate} • ${widget.slotTime}"),

          const SizedBox(height: 20),

          _buildDurationSelector(),

          const SizedBox(height: 16),

          loadingPrice
              ? const CircularProgressIndicator()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pricingType == "hybrid")
                      _priceRow("Visit charge", visitCharge),

                    _priceRow("Service", serviceCost),
                    _priceRow("Platform fee", platformFee),
                    _priceRow("Tax", tax),
                    const Divider(),
                    _priceRow("Total", totalPrice, bold: true),
                  ],
                ),

          const SizedBox(height: 10),

          TextButton(
            onPressed: _applyCoupon,
            child: const Text("Apply Coupon"),
          ),

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: payingWallet ? null : _payWithWallet,
            child: payingWallet
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Pay with Wallet"),
          ),

          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: payingOnline ? null : _payWithRazorpay,
            child: payingOnline
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Pay Online"),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text("₹${amount.toStringAsFixed(0)}",
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

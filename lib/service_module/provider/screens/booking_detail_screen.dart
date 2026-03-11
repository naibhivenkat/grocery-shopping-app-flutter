

import 'package:flutter/material.dart';
import '../../../services/session_manager.dart';
import '../api/service_api.dart';
import '../utils/provider_theme.dart';
import '../utils/ui_helpers.dart';
import 'chat_screen.dart';
import 'provider_location_service.dart';

class BookingDetailScreen extends StatefulWidget {
  final String providerId;
  final String bookingId;

  const BookingDetailScreen({
    super.key,
    required this.providerId,
    required this.bookingId,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _loading = true;
  Map<String, dynamic>? _booking;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ServiceApi.bookingDetail(widget.bookingId);
      setState(() => _booking = res["booking"]);
      print("BOOKINGS ---->>> $res['booking']");
    } catch (e) {
      UIHelpers.showSnack(context, "Failed to load booking", error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ───────────────── ACTIONS ─────────────────

  Future<void> _accept() async {
    await ServiceApi.acceptBooking(
      bookingId: widget.bookingId,
      providerId: widget.providerId,
    );
    UIHelpers.showSnack(context, "Booking accepted");
    _load();
  }

  Future<void> _reject() async {
    final reason = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reject Booking"),
        content: TextField(
          controller: reason,
          decoration: const InputDecoration(labelText: "Reason"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Reject")),
        ],
      ),
    );

    if (ok != true) return;

    await ServiceApi.rejectBooking(
      bookingId: widget.bookingId,
      providerId: widget.providerId,
      reason: reason.text,
    );

    UIHelpers.showSnack(context, "Booking rejected");
    _load();
  }



  Future<void> _start() async {

  await ServiceApi.startService(
    bookingId: widget.bookingId,
    providerId: widget.providerId,
  );

  /// 🔥 START LIVE GPS
  ProviderLocationService.startTracking(
  bookingId: widget.bookingId,
  providerId: widget.providerId,
);

  UIHelpers.showSnack(context, "Service started");
  _load();
}


  Future<void> _complete() async {

  await ServiceApi.completeService(
    bookingId: widget.bookingId,
    providerId: widget.providerId,
  );

ProviderLocationService.stopTracking(widget.bookingId);


  UIHelpers.showSnack(context, "Service completed");
  _load();
}


  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ProviderTheme.themeData(),
      child: Scaffold(
        appBar: AppBar(title: const Text("Booking Details")),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _booking == null
                ? const Center(child: Text("Booking not found"))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _customerCard(),
                      const SizedBox(height: 10),
                      _serviceTitle(),
                      const SizedBox(height: 10),
                      _slotCard(),
                      const SizedBox(height: 10),
                      _paymentCard(),
                      const SizedBox(height: 10),
                      _invoiceCard(),
                      const SizedBox(height: 20),
                      _actions(),
                    ],
                  ),
      ),
    );
  }

  // ───────────────── CUSTOMER ─────────────────

  Widget _customerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0,2))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.blue.shade100,
            child: const Icon(Icons.person, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _booking!["customer_name"] ?? "Customer",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(_booking!["customer_phone"] ?? "",
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
      
          IconButton(
  icon: const Icon(Icons.chat_bubble, color: Colors.blue, size: 28),
  onPressed: () async {

    final myUserId = await SessionManager.getServiceUserId();

    if (myUserId == null) {
      UIHelpers.showSnack(context, "User not logged in", error: true);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          bookingId: widget.bookingId,
          myUserId: myUserId,
        ),
      ),
    );
  },
),

        ],
      ),
    );
  }

  Widget _serviceTitle() {
    return Text(
      _booking!["service_title"] ?? "Service",
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    );
  }

  // ───────────────── SLOT ─────────────────

  Widget _slotCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "${_booking!["slot_date"]} • ${_booking!["slot_time"]}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          _statusChip(),
        ],
      ),
    );
  }

  // ───────────────── PAYMENT ─────────────────

  Widget _paymentCard() {
    final paid = _booking!["payment_status"] == "paid";

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: paid
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.red.shade400, Colors.red.shade600],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.currency_rupee, color: Colors.white, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "₹${_booking!["total_cost"] ?? 0}",
              style: const TextStyle(
                  fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            paid ? "PAID" : "UNPAID",
            style: const TextStyle(color: Colors.white),
          )
        ],
      ),
    );
  }

  // ───────────────── INVOICE ─────────────────

  Widget _invoiceCard() {
  final earning = _booking!["provider_earning"] ??
      _booking!["service_price"] ??
      _booking!["total_cost"] ??
      0;

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: _line("Service earning", "₹$earning"),
    ),
  );
}


  Widget _statusChip() {
    final s = _booking!["status"] ?? "";
    Color c = Colors.grey;

    if (s == "incoming" || s == "confirmed") c = Colors.orange;
    if (s == "accepted") c = Colors.blue;
    if (s == "started") c = Colors.purple;
    if (s == "completed") c = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6)),
      child: Text(s.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }

  // ───────────────── ACTION BUTTONS ─────────────────

  Widget _actions() {
    final status = _booking!["status"];

    if (status != "accepted" &&
        status != "started" &&
        status != "completed" &&
        status != "rejected") {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _accept,
              child: const Text("Accept"),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _reject,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Reject"),
            ),
          ),
        ],
      );
    }

    if (status == "accepted") {
      return ElevatedButton(
        onPressed: _start,
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
        child: const Text("Start Service"),
      );
    }

    if (status == "started") {
      return ElevatedButton(
        onPressed: _complete,
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
        child: const Text("Complete Service"),
      );
    }

    return const SizedBox();
  }

  Widget _line(String l, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(color: ProviderTheme.subText)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}


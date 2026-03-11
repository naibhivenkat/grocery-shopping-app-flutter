import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/session_manager.dart';
import '../api/service_api.dart';
import '../utils/provider_theme.dart';
import '../utils/ui_helpers.dart';
import 'chat_screen.dart';
import 'live_provider_tracking_screen.dart';

class CustomerBookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const CustomerBookingDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<CustomerBookingDetailScreen> createState() =>
      _CustomerBookingDetailScreenState();
}

class _CustomerBookingDetailScreenState
    extends State<CustomerBookingDetailScreen> {

  bool _loading = true;
  Map<String, dynamic>? _booking;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      _myUserId = await SessionManager.getServiceUserId();
      final res = await ServiceApi.bookingDetail(widget.bookingId);
      setState(() => _booking = res["booking"]);
    } catch (e) {
      UIHelpers.showSnack(context, "Failed to load booking", error: true);
    }

    setState(() => _loading = false);
  }

  // ───────────────── CHAT ─────────────────

  void _openChat() {
    if (_myUserId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          bookingId: widget.bookingId,
          myUserId: _myUserId!,
        ),
      ),
    );
  }

  // ───────────────── CALL PROVIDER ─────────────────

  void _callProvider() async {
    final phone = _booking?["provider_phone"];

    if (phone == null || phone.toString().isEmpty) {
      UIHelpers.showSnack(context, "Phone not available");
      return;
    }

    final url = Uri.parse("tel:$phone");

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      UIHelpers.showSnack(context, "Cannot open dialer");
    }
  }

  // ───────────────── CANCEL BOOKING ─────────────────

  Future<void> _cancelBooking() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel booking?"),
        content: const Text("Refund will be processed if eligible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes cancel")),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await ServiceApi.cancelBooking(widget.bookingId);
      UIHelpers.showSnack(context, "Booking cancelled");
      _load();
    } catch (e) {
      UIHelpers.showSnack(context, "Cancel failed", error: true);
    }
  }

  // ───────────────── STATUS CHIP ─────────────────

  Widget _statusChip(String status) {
    Color c = Colors.grey;

    if (status == "confirmed") c = Colors.orange;
    if (status == "accepted") c = Colors.blue;
    if (status == "started") c = Colors.purple;
    if (status == "completed") c = Colors.green;
    if (status == "rejected") c = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  // ───────────────── STATUS TIMELINE ─────────────────

  Widget _statusTimeline() {
    final status = _booking!["status"];

    final steps = [
      "confirmed",
      "accepted",
      "started",
      "completed"
    ];

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Service Progress",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Column(
              children: steps.map((s) {
                final done = steps.indexOf(status) >= steps.indexOf(s);
                return Row(
                  children: [
                    Icon(
                      done ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: done ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(s.toUpperCase()),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────── HEADER ─────────────────

  Widget _header() {
    return ListTile(
      title: Text(
        _booking!["service_title"] ?? "Service",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      subtitle: Text(
        "${DateFormat("dd MMM yyyy").format(DateTime.parse(_booking!["slot_date"]))} • ${_booking!["slot_time"]}",
      ),
      trailing: _statusChip(_booking!["status"]),
    );
  }

  // ───────────────── PROVIDER CARD ─────────────────

  Widget _providerCard() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(_booking!["provider_name"] ?? "Provider"),
        subtitle: Text(_booking!["provider_phone"] ?? ""),
        trailing: IconButton(
          icon: const Icon(Icons.call),
          onPressed: _callProvider,
        ),
      ),
    );
  }

  // ───────────────── PAYMENT ─────────────────

  Widget _paymentCard() {
    final total = _booking!["final_total"] ?? 0;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _line("Service price", _booking!["service_price"]),
            _line("Platform fee", _booking!["platform_fee"]),
            _line("Tax", _booking!["tax"]),
            const Divider(),
            _line("Total paid", total, bold: true),
          ],
        ),
      ),
    );
  }

  Widget _line(String l, dynamic v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l),
          Text("₹${v ?? 0}",
              style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
        ],
      ),
    );
  }



    Widget _actions() {
  final status = _booking!["status"];

  // hide buttons if booking finished
  if (status == "completed" || status == "rejected") {
    return const SizedBox();
  }

  return Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      children: [

        /// 🟢 LIVE TRACK PROVIDER
        if (status == "accepted" || status == "started")
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LiveProviderTrackingScreen(
                    bookingId: widget.bookingId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.location_on),
            label: const Text("Track provider live"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),

        if (status == "accepted" || status == "started")
          const SizedBox(height: 10),

        /// 💬 CHAT
        ElevatedButton.icon(
          onPressed: _openChat,
          icon: const Icon(Icons.chat),
          label: const Text("Chat with provider"),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        ),

        const SizedBox(height: 10),

        /// ❌ CANCEL
        if (status == "confirmed" || status == "accepted")
          ElevatedButton.icon(
            onPressed: _cancelBooking,
            icon: const Icon(Icons.cancel),
            label: const Text("Cancel booking"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
      ],
    ),
  );
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
          children: [
            _header(),
            _statusTimeline(),
            _providerCard(),
            _paymentCard(),
            _actions(),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../api/service_api.dart';
import '../utils/provider_theme.dart';
import '../utils/ui_helpers.dart';

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
    } catch (e) {
      UIHelpers.showSnack(
        context,
        e.toString().replaceFirst("Exception: ", ""),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept() async {
    try {
      await ServiceApi.acceptBooking(
        bookingId: widget.bookingId,
        providerId: widget.providerId,
      );
      UIHelpers.showSnack(context, "Booking accepted ✅");
      _load();
    } catch (e) {
      UIHelpers.showSnack(
        context,
        e.toString().replaceFirst("Exception: ", ""),
        error: true,
      );
    }
  }

  Future<void> _reject() async {
    final reason = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reject Booking"),
        content: TextField(
          controller: reason,
          decoration: const InputDecoration(labelText: "Reason (required)"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Reject"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    if (reason.text.trim().isEmpty) {
      UIHelpers.showSnack(context, "Reason required", error: true);
      return;
    }

    try {
      await ServiceApi.rejectBooking(
        bookingId: widget.bookingId,
        providerId: widget.providerId,
        reason: reason.text.trim(),
      );
      UIHelpers.showSnack(context, "Booking rejected + refund initiated ✅");
      _load();
    } catch (e) {
      UIHelpers.showSnack(
        context,
        e.toString().replaceFirst("Exception: ", ""),
        error: true,
      );
    }
  }

  Future<void> _start() async {
    try {
      await ServiceApi.startService(
        bookingId: widget.bookingId,
        providerId: widget.providerId,
      );
      UIHelpers.showSnack(context, "Service started ✅");
      _load();
    } catch (e) {
      UIHelpers.showSnack(
        context,
        e.toString().replaceFirst("Exception: ", ""),
        error: true,
      );
    }
  }

  Future<void> _complete() async {
    try {
      await ServiceApi.completeService(
        bookingId: widget.bookingId,
        providerId: widget.providerId,
      );
      UIHelpers.showSnack(context, "Service completed ✅");
      _load();
    } catch (e) {
      UIHelpers.showSnack(
        context,
        e.toString().replaceFirst("Exception: ", ""),
        error: true,
      );
    }
  }

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
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: ListView(
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Slot: ${_booking!["slot_date"]} ${_booking!["slot_time"]}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Status: ${_booking!["status"]}",
                                  style: const TextStyle(color: ProviderTheme.subText),
                                ),
                                const SizedBox(height: 10),
                                const Divider(),
                                const Text(
                                  "Invoice UI Preview",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _line("Total", "₹${_booking!["total_cost"] ?? 0}"),
                                _line("Discount", "₹${_booking!["discount"] ?? 0}"),
                                _line("Commission", "₹${_booking!["commission"] ?? 0}"),
                                const SizedBox(height: 6),
                                const Text(
                                  "Printable PDF/HTML will be added later.\nThis is preview only.",
                                  style: TextStyle(color: ProviderTheme.subText),
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _actions(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _actions() {
    final status = _booking!["status"] ?? "incoming";

    if (status == "incoming") {
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: const Text("Reject"),
            ),
          ),
        ],
      );
    }

    if (status == "accepted") {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _start,
          child: const Text("Start Service"),
        ),
      );
    }

    if (status == "started") {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _complete,
          child: const Text("Complete Service"),
        ),
      );
    }

    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text("No actions available."),
      ),
    );
  }

  Widget _line(String l, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(color: ProviderTheme.subText)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

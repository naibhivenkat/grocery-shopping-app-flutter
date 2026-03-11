import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/session_manager.dart';
import '../api/service_api.dart';
import '../utils/provider_theme.dart';
import '../utils/service_catalog.dart';
import '../utils/ui_helpers.dart';
import 'customer_booking_detail_screen.dart';

class CustomerMyBookingsScreen extends StatefulWidget {
  const CustomerMyBookingsScreen({super.key});

  @override
  State<CustomerMyBookingsScreen> createState() =>
      _CustomerMyBookingsScreenState();
}

class _CustomerMyBookingsScreenState extends State<CustomerMyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _loading = true;
  List<dynamic> _bookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  // ───────── DATE PARSER ─────────

  DateTime _parseDateTime(dynamic b) {
    try {
      return DateFormat("yyyy-MM-dd hh:mm a")
          .parse("${b["slot_date"]} ${b["slot_time"]}");
    } catch (_) {
      return DateTime.parse("${b["slot_date"]} ${b["slot_time"]}");
    }
  }

  // ───────── LOAD BOOKINGS ─────────

  Future<void> _loadBookings() async {
    setState(() => _loading = true);

    try {
      final userId = await SessionManager.getServiceUserId();

      if (userId == null) {
        UIHelpers.showSnack(context, "Login required", error: true);
        return;
      }

      final res = await ServiceApi.myBookings(userId);

      // remove invalid bookings
      res.removeWhere((b) =>
          (b["amount"] ?? 0) <= 0 ||
          b["service_title"] == null ||
          b["service_title"].toString().trim().isEmpty);

      res.sort((a, b) => _parseDateTime(a).compareTo(_parseDateTime(b)));

      setState(() => _bookings = res);
    } catch (e) {
      UIHelpers.showSnack(context, "Failed to load bookings", error: true);
    }

    setState(() => _loading = false);
  }

  // ───────── AUTO MOVE COMPLETED ─────────

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {}); // refresh state → completed move to Past
    });
  }

  // ───────── FILTER BUCKETS ─────────

  List<dynamic> _active() =>
      _bookings.where((b) =>
          ["confirmed", "accepted", "started"].contains(b["status"])).toList();

  List<dynamic> _past() =>
      _bookings.where((b) => b["status"] == "completed").toList();

  List<dynamic> _cancelled() =>
      _bookings.where((b) =>
          ["rejected", "cancelled"].contains(b["status"])).toList();

  // ───────── GROUP BY SERVICE ─────────

  Map<String, List<dynamic>> _groupByService(List<dynamic> list) {
    Map<String, List<dynamic>> grouped = {};

    for (var b in list) {
      final service = b["service_title"];

      if (!grouped.containsKey(service)) {
        grouped[service] = [];
      }

      grouped[service]!.add(b);
    }

    return grouped;
  }

  // ───────── STATUS CHIP ─────────

  Widget _statusChip(String status) {
    Color c = Colors.grey;

    if (status == "confirmed") c = Colors.orange;
    if (status == "accepted") c = Colors.blue;
    if (status == "started") c = Colors.purple;
    if (status == "completed") c = Colors.green;
    if (status == "rejected" || status == "cancelled") c = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(fontSize: 11, color: Colors.white),
      ),
    );
  }

  // ───────── PAYMENT BADGE ─────────

  Widget _paymentBadge(String? payment) {
    if (payment == null) return const SizedBox();

    Color c = Colors.grey;

    if (payment == "paid") c = Colors.green;
    if (payment == "cod") c = Colors.orange;
    if (payment == "refunded") c = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        payment.toUpperCase(),
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
    );
  }

  // ───────── NEXT BOOKING LOGIC ─────────

  dynamic _nextUpcomingBooking() {
    final now = DateTime.now();
    for (var b in _active()) {
      if (_parseDateTime(b).isAfter(now)) return b;
    }
    return null;
  }

  // ───────── BOOKING ROW ─────────

  Widget _bookingRow(dynamic b) {
    final dt = _parseDateTime(b);
    final isNext = _nextUpcomingBooking() == b;

    return Column(
      children: [
        Container(
          color: isNext ? Colors.yellow.withOpacity(0.15) : null,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            title: Text(
              DateFormat("dd MMM • hh:mm a").format(dt),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("₹${b["amount"] ?? 0}",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text("Provider: ${b["provider_name"] ?? "Assigned soon"}",
                    style: const TextStyle(fontSize: 13)),
              ],
            ),
            trailing: Column(
              children: [
                _statusChip(b["status"]),
                const SizedBox(height: 4),
                _paymentBadge(b["payment_status"]),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CustomerBookingDetailScreen(bookingId: b["id"]),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1), // separator line
      ],
    );
  }

  // ───────── SERVICE CARD ─────────

  Widget _serviceCard(String service, List<dynamic> bookings) {
    final catalog = ServiceCatalog.byId(service.toLowerCase());
    final icon = catalog?.icon ?? Icons.miscellaneous_services;
    final color = catalog?.color ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(service,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: Text("${bookings.length} bookings"),
        children: bookings.map(_bookingRow).toList(),
      ),
    );
  }

  // ───────── TAB VIEW ─────────

  Widget _tabView(List<dynamic> list) {
    if (list.isEmpty) {
      return const Center(child: Text("No bookings yet"));
    }

    final grouped = _groupByService(list);

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView(
        children: grouped.entries
            .map((e) => _serviceCard(e.key, e.value))
            .toList(),
      ),
    );
  }

  // ───────── UI ─────────

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ProviderTheme.themeData(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Bookings"),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "Active"),
              Tab(text: "Past"),
              Tab(text: "Cancelled"),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _tabView(_active()),
                  _tabView(_past()),
                  _tabView(_cancelled()),
                ],
              ),
      ),
    );
  }
}

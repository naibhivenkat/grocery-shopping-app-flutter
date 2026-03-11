import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/service_api.dart';
import '../utils/provider_theme.dart';
import '../utils/ui_helpers.dart';
import 'booking_detail_screen.dart';

import '../../../services/session_manager.dart';
import 'chat_screen.dart';

/// ───────────────── MEMORY CACHE ─────────────────
class BookingCache {
  static final BookingCache _instance = BookingCache._internal();
  factory BookingCache() => _instance;
  BookingCache._internal();

  List<dynamic>? bookings;
  DateTime? lastFetched;
}

class ProviderBookingsScreen extends StatefulWidget {
  final String providerId;
  const ProviderBookingsScreen({super.key, required this.providerId});

  @override
  State<ProviderBookingsScreen> createState() =>
      _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {

  late TabController _tab;
  Timer? _backgroundTimer;

  final List<String> _tabs = ["Today", "Future", "Accepted", "Past", "Rejected"];

  bool _loading = true;
  Map<String, Map<String, List<dynamic>>> _grouped = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _loadAll();

    _backgroundTimer = Timer.periodic(const Duration(seconds: 40), (_) {
      _loadAll(forceRefresh: true, silent: true);
    });
  }

  @override
  void dispose() {
    _backgroundTimer?.cancel();
    _tab.dispose();
    super.dispose();
  }

  // ───────────────── LOAD BOOKINGS ─────────────────

  Future<void> _loadAll({bool forceRefresh = false, bool silent = false}) async {
    final cache = BookingCache();

    if (forceRefresh) {
      cache.bookings = null;
    }

    try {
      if (!silent) setState(() => _loading = true);

      final bookings =
          await ServiceApi.providerBookings(widget.providerId, "all");

      cache.bookings = bookings;

      if (mounted) {
        setState(() {
          _grouped = _bucketBookings(bookings);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ───────────────── BUCKET ENGINE ─────────────────

  Map<String, Map<String, List<dynamic>>> _bucketBookings(
      List<dynamic> bookings) {

    final Map<String, List<dynamic>> buckets = {
      "Today": [],
      "Future": [],
      "Accepted": [],
      "Past": [],
      "Rejected": [],
    };

    for (final b in bookings) {
      if (b["payment_status"] != "paid") continue;

      final bucket = _bucket(b);
      buckets[bucket]!.add(b);
    }

    final Map<String, Map<String, List<dynamic>>> grouped = {};
    for (final tab in buckets.keys) {
      grouped[tab] = _groupByService(_prioritySort(buckets[tab]!));
    }

    return grouped;
  }

  String _bucket(dynamic b) {
    final status = b["status"];
    final dt = DateTime.tryParse("${b["slot_date"]} ${b["slot_time"]}");
    if (dt == null) return "Future";
    final now = DateTime.now();

    if (status == "rejected") return "Rejected";
    if (status == "completed") return "Past";
    if (status == "accepted" || status == "started") return "Accepted";

    if (_isSameDay(dt, now)) return "Today";
    if (dt.isAfter(now)) return "Future";
    return "Past";
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ───────────────── PRIORITY SORT ─────────────────

  List<dynamic> _prioritySort(List<dynamic> bookings) {
    bookings.sort((a, b) {
      final da = DateTime.tryParse("${a["slot_date"]} ${a["slot_time"]}");
      final db = DateTime.tryParse("${b["slot_date"]} ${b["slot_time"]}");

      int pa = _priorityScore(da);
      int pb = _priorityScore(db);

      if (pa != pb) return pb.compareTo(pa);
      return (b["amount"] ?? 0).compareTo(a["amount"] ?? 0);
    });

    return bookings;
  }

  int _priorityScore(DateTime? date) {
    if (date == null) return 0;
    final diff = date.difference(DateTime.now()).inMinutes;
    if (diff > 0 && diff <= 120) return 5;
    if (_isSameDay(date, DateTime.now())) return 4;
    if (date.isAfter(DateTime.now())) return 3;
    return 1;
  }

  // ───────────────── GROUP BY SERVICE ─────────────────

  Map<String, List<dynamic>> _groupByService(List<dynamic> bookings) {
    final map = <String, List<dynamic>>{};
    for (final b in bookings) {
      final service = b["service_title"] ?? "Service";
      map.putIfAbsent(service, () => []);
      map[service]!.add(b);
    }
    return map;
  }

  // ───────────────── URGENCY ─────────────────

  bool _isUrgent(dynamic b) {
    final dt = DateTime.tryParse("${b["slot_date"]} ${b["slot_time"]}");
    if (dt == null) return false;
    final diff = dt.difference(DateTime.now()).inMinutes;
    return diff > 0 && diff <= 90;
  }

  bool _needsAction(dynamic b) =>
      (b["status"] == "incoming" || b["status"] == "confirmed");

  // ───────────────── BOOKING TILE ─────────────────

  Widget _bookingTile(dynamic b) {
    final urgent = _isUrgent(b);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: urgent
            ? Border.all(color: Colors.red, width: 1.5)
            : Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingDetailScreen(
                providerId: widget.providerId,
                bookingId: b["id"],
              ),
            ),
          );
        },

        title: Row(
          children: [
            Expanded(
              child: Text(b["customer_name"],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),

            if (_needsAction(b))
              _chip("ACTION", Colors.orange),

            if (urgent)
              _chip("URGENT", Colors.red),
          ],
        ),

        subtitle: Text(
            "${DateFormat("EEE, dd MMM").format(DateTime.parse(b["slot_date"]))} • ${b["slot_time"]}"),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [

            /// 💬 CHAT BUTTON
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
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
                      bookingId: b["id"],
                      myUserId: myUserId,
                    ),
                  ),
                );

                  print("Navigating to chat with bookingId: ${b["id"]} and myUserId: $myUserId and  ${b["requester_id"]}");
                  print("$b");
                 },
            ),

            /// PRICE
            Text("₹ ${b["amount"]}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.white)),
    );
  }

  // ───────────────── SERVICE GROUP CARD ─────────────────

  Widget _serviceGroupCard(String service, List<dynamic> bookings) {
    final todayCount = bookings.where((b) => _bucket(b) == "Today").length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(child: Text(service,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
            if (todayCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text("$todayCount today",
                    style: const TextStyle(fontSize: 11)),
              )
          ],
        ),
        children: bookings.map(_bookingTile).toList(),
      ),
    );
  }

  Widget _tabView(String status) {
    final map = _grouped[status] ?? {};
    if (map.isEmpty) return const Center(child: Text("No bookings"));

    return RefreshIndicator(
      onRefresh: () => _loadAll(forceRefresh: true),
      child: ListView(
        children: map.entries.map((e) => _serviceGroupCard(e.key, e.value)).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Theme(
      data: ProviderTheme.themeData(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Service Requests"),
          actions: [
            IconButton(
              onPressed: () => _loadAll(forceRefresh: true),
              icon: const Icon(Icons.refresh),
            )
          ],
          bottom: TabBar(
            controller: _tab,
            isScrollable: true,
            tabs: const [
              Tab(text: "Today"),
              Tab(text: "Future"),
              Tab(text: "Accepted"),
              Tab(text: "Past"),
              Tab(text: "Rejected"),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tab,
                children: _tabs.map(_tabView).toList(),
              ),
      ),
    );
  }
}


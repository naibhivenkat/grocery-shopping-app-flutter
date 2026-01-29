import 'package:flutter/material.dart';
import '../api/service_api.dart';
import '../utils/provider_theme.dart';
import '../utils/ui_helpers.dart';
import 'booking_detail_screen.dart';

class ProviderBookingsScreen extends StatefulWidget {
  final String providerId;
  const ProviderBookingsScreen({super.key, required this.providerId});

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen> with TickerProviderStateMixin {
  late TabController _tab;
  final List<String> _tabs = ["incoming", "upcoming", "completed", "rejected"];
  bool _loading = true;
  Map<String, List<dynamic>> _data = {};

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final Map<String, List<dynamic>> tmp = {};
      for (final s in _tabs) {
        tmp[s] = await ServiceApi.providerBookings(widget.providerId, s);
      }
      setState(() => _data = tmp);
    } catch (e) {
      UIHelpers.showSnack(context, e.toString().replaceFirst("Exception: ", ""), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _list(String status) {
    final items = _data[status] ?? [];
    if (items.isEmpty) return const Center(child: Text("No bookings"));
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (_, i) {
        final b = items[i];
        return Card(
          child: ListTile(
            title: Text("Booking • ${b["slot_date"]} ${b["slot_time"]}"),
            subtitle: Text("Status: ${b["status"]}"),
            trailing: const Icon(Icons.chevron_right),
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
              _loadAll();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ProviderTheme.themeData(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Service Requests"),
          actions: [IconButton(onPressed: _loadAll, icon: const Icon(Icons.refresh))],
          bottom: TabBar(
            controller: _tab,
            isScrollable: true,
            tabs: const [
              Tab(text: "Incoming"),
              Tab(text: "Upcoming"),
              Tab(text: "Completed"),
              Tab(text: "Rejected"),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tab,
                children: _tabs.map(_list).toList(),
              ),
      ),
    );
  }
}

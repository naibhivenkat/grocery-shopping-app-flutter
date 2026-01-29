import 'package:flutter/material.dart';
import '../api/service_api.dart';
import '../utils/provider_theme.dart';
import '../utils/ui_helpers.dart';

class ProviderEarningsScreen extends StatefulWidget {
  final String providerId;
  const ProviderEarningsScreen({super.key, required this.providerId});

  @override
  State<ProviderEarningsScreen> createState() => _ProviderEarningsScreenState();
}

class _ProviderEarningsScreenState extends State<ProviderEarningsScreen> {
  bool _loading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ServiceApi.earningsSummary(widget.providerId);
      setState(() => _data = res);
    } catch (e) {
      UIHelpers.showSnack(context, e.toString().replaceFirst("Exception: ", ""), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ProviderTheme.themeData(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Earnings"),
          actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _data == null
                ? const Center(child: Text("No data"))
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
                                const Text("Summary", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 10),
                                _row("Completed Jobs", "${_data!["completed_jobs"] ?? 0}"),
                                _row("Pending Earnings", "₹${_data!["pending_amount"] ?? 0}"),
                                _row("Paid History Total", "₹${_data!["paid_total"] ?? 0}"),
                                _row("Incoming Bookings", "${_data!["incoming_count"] ?? 0}"),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Payout Schedule", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 8),
                                Text(
                                  _data!["payout_mode"] ?? "weekly",
                                  style: const TextStyle(color: ProviderTheme.subText),
                                ),
                                const SizedBox(height: 8),
                                const Text("Weekly/Monthly payout history will show here."),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
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

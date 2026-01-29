import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/service_api.dart';
import '../utils/provider_theme.dart';
import '../utils/ui_helpers.dart';

class AvailabilityCalendarScreen extends StatefulWidget {
  final String providerId;
  const AvailabilityCalendarScreen({super.key, required this.providerId});

  @override
  State<AvailabilityCalendarScreen> createState() => _AvailabilityCalendarScreenState();
}

class _AvailabilityCalendarScreenState extends State<AvailabilityCalendarScreen> {
  DateTime _selected = DateTime.now();
  bool _loading = true;
  List<dynamic> _slots = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _dateKey(DateTime d) => DateFormat("yyyy-MM-dd").format(d);

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ServiceApi.getAvailability(widget.providerId, _dateKey(_selected));
      setState(() => _slots = res["slots"] ?? []);
    } catch (e) {
      UIHelpers.showSnack(context, e.toString().replaceFirst("Exception: ", ""), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _editable(String status) => status == "available" || status == "unavailable";

  Future<void> _toggleSlot(Map slot) async {
    final status = slot["status"] ?? "available";
    if (!_editable(status)) {
      UIHelpers.showSnack(context, "Booked/Locked slots cannot be edited", error: true);
      return;
    }

    final next = status == "available" ? "unavailable" : "available";
    try {
      await ServiceApi.updateSlots({
        "provider_id": widget.providerId,
        "date": _dateKey(_selected),
        "updates": [
          {"time": slot["time"], "status": next}
        ]
      });
      _load();
    } catch (e) {
      UIHelpers.showSnack(context, e.toString().replaceFirst("Exception: ", ""), error: true);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case "available":
        return Colors.green.shade600;
      case "booked":
        return Colors.blue.shade600;
      case "locked":
        return Colors.orange.shade700;
      case "unavailable":
        return Colors.grey.shade600;
      case "rejected":
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = DateFormat("EEE, dd MMM yyyy").format(_selected);
    return Theme(
      data: ProviderTheme.themeData(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Availability Calendar"),
          actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      IconButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now().subtract(const Duration(days: 1)),
                            lastDate: DateTime.now().add(const Duration(days: 60)),
                            initialDate: _selected,
                          );
                          if (picked != null) {
                            setState(() => _selected = picked);
                            _load();
                          }
                        },
                        icon: const Icon(Icons.calendar_month),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _slots.isEmpty
                        ? const Center(child: Text("No slots generated for this date"))
                        : ListView.builder(
                            itemCount: _slots.length,
                            itemBuilder: (_, i) {
                              final slot = _slots[i];
                              final status = slot["status"] ?? "available";
                              return Card(
                                child: ListTile(
                                  title: Text(slot["time"] ?? ""),
                                  subtitle: Text("Status: $status"),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _statusColor(status).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  onTap: () => _toggleSlot(Map<String, dynamic>.from(slot)),
                                ),
                              );
                            },
                          ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

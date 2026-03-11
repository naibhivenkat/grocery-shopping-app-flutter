import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/service_api.dart';
import '../requests/service_duration_pricing_payment_sheet.dart';
import '../utils/provider_theme.dart';
import '../utils/ui_helpers.dart';
import 'package:grocery_app_new_flutter/services/session_manager.dart';

class AvailabilityCalendarScreen extends StatefulWidget {
  final String providerId;
  final String serviceName;

  // NEW (minimal addition)
  final String? serviceId;
  final bool bookingMode;

  const AvailabilityCalendarScreen({
    super.key,
    required this.providerId,
    required this.serviceName,
    this.serviceId,
    this.bookingMode = false,
  });

  @override
  State<AvailabilityCalendarScreen> createState() =>
      _AvailabilityCalendarScreenState();
}

class _AvailabilityCalendarScreenState
    extends State<AvailabilityCalendarScreen> {
  DateTime _selected = DateTime.now();
  bool _loading = true;
  List<dynamic> _slots = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _dateKey(DateTime d) => DateFormat("yyyy-MM-dd").format(d);

  // ───────────────── DATE HANDLING ─────────────────

  List<DateTime> get _weekDates =>
      List.generate(7, (i) => DateTime.now().add(Duration(days: i)));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selected = picked);
      _load();
    }
  }

  // ───────────────── DATA ─────────────────

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ServiceApi.getAvailability(
        widget.providerId,
        _dateKey(_selected),
      );
      List<dynamic> allSlots = res["slots"] ?? [];

// hide past slots if selected date = today
if (DateUtils.isSameDay(_selected, DateTime.now())) {
  final now = TimeOfDay.now();

  allSlots = allSlots.where((s) {
    final parts = s["time"].split(":");
    final slotTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    return slotTime.hour > now.hour ||
        (slotTime.hour == now.hour && slotTime.minute > now.minute);
  }).toList();
}

setState(() => _slots = allSlots);

    } catch (e) {
      UIHelpers.showSnack(context, e.toString(), error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  // ───────────────── PROVIDER SLOT UPDATE ─────────────────

  Future<void> _setSlot(String time, String status) async {
    await ServiceApi.updateSlots({
      "provider_id": widget.providerId,
      "date": _dateKey(_selected),
      "updates": [
        {"time": time, "status": status}
      ]
    });
    _load();
  }


    Future<void> _bookSlot(Map slot) async {
  if (slot["status"] != "available") {
    UIHelpers.showSnack(context, "Slot not available", error: true);
    return;
  }

  // STEP 1 — ASK DURATION
  final duration = await showModalBottomSheet<int>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Select Service Duration",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ListTile(
            title: const Text("30 minutes"),
            onTap: () => Navigator.pop(context, 30),
          ),
          ListTile(
            title: const Text("1 hour"),
            onTap: () => Navigator.pop(context, 60),
          ),
          ListTile(
            title: const Text("2 hours"),
            onTap: () => Navigator.pop(context, 120),
          ),
        ],
      ),
    ),
  );

  if (duration == null) return;

  // STEP 2 — CONFIRM BOOKING
  final confirm = await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Confirm Booking"),
      content: Text(
        "Book ${slot["time"]} for $duration mins on ${_dateKey(_selected)}?",
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel")),
        ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Book")),
      ],
    ),
  );

  if (confirm != true) return;

  final requesterId = await SessionManager.getServiceRequesterId();

  try {
    await ServiceApi.bookService({
      "service_id": widget.serviceId,
      "provider_id": widget.providerId,
      "requester_id": requesterId,
      "slot_date": _dateKey(_selected),
      "slot_time": slot["time"],
      "duration": duration, // ⭐ NEW FIELD
    });

    UIHelpers.showSnack(context, "Booking confirmed");
    Navigator.pop(context);
  } catch (e) {
    UIHelpers.showSnack(context, e.toString(), error: true);
  }
}


  // ───────────────── SLOT ACTIONS (PROVIDER) ─────────────────

  void _openSlotActions(Map slot) {
    final time = slot["time"];
    final status = slot["status"];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$time • ${status.toUpperCase()}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text("Mark Available"),
              enabled: status != "available",
              onTap: status == "available"
                  ? null
                  : () {
                      Navigator.pop(context);
                      _setSlot(time, "available");
                    },
            ),

            ListTile(
              leading: const Icon(Icons.block),
              title: const Text("Mark Unavailable"),
              enabled: status != "unavailable",
              onTap: status == "unavailable"
                  ? null
                  : () {
                      Navigator.pop(context);
                      _setSlot(time, "unavailable");
                    },
            ),

            if (!_isEditable(status)) ...[
              const Divider(),
              Text(
                _readOnlyReason(status),
                style: const TextStyle(color: Colors.grey),
              ),
            ]
          ],
        ),
      ),
    );
  }

  bool _isEditable(String status) =>
      status == "available" || status == "unavailable";

  String _readOnlyReason(String status) {
    switch (status) {
      case "booked":
        return "This slot is booked by a customer.";
      case "locked":
        return "This slot is locked after acceptance.";
      case "rejected":
        return "This slot was previously rejected.";
      default:
        return "";
    }
  }

  Color _slotColor(String status) {
    switch (status) {
      case "available":
        return Colors.green.shade500;
      case "booked":
        return Colors.red.shade400;
      case "locked":
        return Colors.purple.shade400;
      case "unavailable":
        return Colors.grey.shade400;
      case "rejected":
        return Colors.orange.shade400;
      default:
        return Colors.grey;
    }
  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ProviderTheme.themeData(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Availability Calendar"),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: _pickDate,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _load,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _weekDates.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final d = _weekDates[i];
                    final selected = DateUtils.isSameDay(d, _selected);

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selected = d);
                        _load();
                      },
                      child: Container(
                        width: 60,
                        decoration: BoxDecoration(
                          color:
                              selected ? Colors.blue : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(DateFormat("EEE").format(d),
                                style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : Colors.black54)),
                            Text(DateFormat("dd").format(d),
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: selected
                                        ? Colors.white
                                        : Colors.black)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),
              Text("Service: ${widget.serviceName}",
                  style: const TextStyle(color: ProviderTheme.subText)),

              const SizedBox(height: 12),

              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.builder(
                        itemCount: _slots.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 2.0,
                        ),
                        itemBuilder: (_, i) {
                          final slot = _slots[i];
                          final status = slot["status"];

                          return InkWell(
                            borderRadius: BorderRadius.circular(14),

                            // ⭐ THIS IS THE ONLY UI LOGIC CHANGE
                            onTap: () {
                              if (widget.bookingMode) {
                                showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => ServiceDurationPricingSheet(
                                providerId: widget.providerId,
                                serviceId: widget.serviceId!,
                                slotDate: _dateKey(_selected),
                                slotTime: slot["time"],
                                serviceData: {}, 
                              ),
                            );

                              } else {
                                _openSlotActions(slot);
                              }
                            },

                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _slotColor(status),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    slot["time"],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    status,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../api/service_api.dart';
import '../utils/provider_theme.dart';
import '../utils/ui_helpers.dart';
import '../utils/service_catalog.dart';
import 'service_details_screen.dart';

class MyServicesScreen extends StatefulWidget {
  final String providerId;
  final String serviceCategoryId;

  const MyServicesScreen({
    super.key,
    required this.providerId,
    required this.serviceCategoryId,
  });

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
  
}

class _MyServicesScreenState extends State<MyServicesScreen>
    with SingleTickerProviderStateMixin {
      bool applyAll = false;
    TimeOfDay? bulkFrom;
    TimeOfDay? bulkTo;
  bool _loading = true;
  List<dynamic> _services = [];

  late TabController _tabController;

  final List<String> _weekDays = const [
    "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // =======================
  // LOAD SERVICES
  // =======================
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ServiceApi.getMyServices(widget.providerId);
      setState(() => _services = res);
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

  // =======================
  // OPEN / CLOSED HELPERS
  // =======================
  bool _isServiceOpenNow(dynamic s) {
    final schedule = s["working_schedule"];
    if (schedule == null || schedule is! Map) return false;

    final weekday = DateTime.now().weekday;
    final now = TimeOfDay.now();

    const days = {
      1: "Mon",
      2: "Tue",
      3: "Wed",
      4: "Thu",
      5: "Fri",
      6: "Sat",
      7: "Sun",
    };

    final today = days[weekday];
    final d = schedule[today];
    if (d == null) return false;
    if (d["closed"] == true) return false;

TimeOfDay parse(String t) {
  try {
    t = t.trim().toUpperCase();

    // Case 1: 09:30 AM / 9:30 PM
    if (t.contains("AM") || t.contains("PM")) {
      final parts = t.split(" ");
      final hm = parts[0].split(":");

      int hour = int.parse(hm[0]);
      int minute = int.parse(hm[1]);
      final isPM = parts[1] == "PM";

      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    }

    // Case 2: 24hr → 09:30
    final p = t.split(":");
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  } catch (e) {
    return TimeOfDay(hour: 0, minute: 0);
  }
}


    final from = d["from"];
    final to = d["to"];
    if (from == null || to == null) return false;

    final fromT = parse(from);
    final toT = parse(to);

    bool inRange(TimeOfDay a, TimeOfDay b) {
      final n = now.hour * 60 + now.minute;
      return n >= a.hour * 60 + a.minute &&
          n <= b.hour * 60 + b.minute;
    }

    if (!inRange(fromT, toT)) return false;

    // lunch break
  final lunchFrom = d["lunch_from"];
final lunchTo = d["lunch_to"];

if (lunchFrom is String &&
    lunchTo is String &&
    lunchFrom.isNotEmpty &&
    lunchTo.isNotEmpty) {
  final lf = parse(lunchFrom);
  final lt = parse(lunchTo);
  if (inRange(lf, lt)) return false;
}


    return true;
  }

  String _statusText(dynamic s) {
    final schedule = s["working_schedule"];
    if (schedule == null || schedule is! Map) return "CLOSED";

    final weekday = DateTime.now().weekday;
    const days = {
      1: "Mon",
      2: "Tue",
      3: "Wed",
      4: "Thu",
      5: "Fri",
      6: "Sat",
      7: "Sun",
    };

    final today = days[weekday];
    final d = schedule[today];
    if (d == null || d["closed"] == true) return "CLOSED TODAY";

    if (_isServiceOpenNow(s)) return "OPEN NOW";

    if (d["from"] != null) return "OPENS AT ${d["from"]}";
    return "CLOSED";
  }

  // =======================
  // TIME PICKER
  // =======================
  Future<TimeOfDay?> _pickTime(BuildContext ctx) async {
    return showTimePicker(context: ctx, initialTime: TimeOfDay.now());
  }

  // =======================
  // PER-DAY SCHEDULE EDITOR (PRO)
  // =======================
 Widget _workingScheduleEditor({
  required Map<String, Map<String, dynamic>> schedule,

    required void Function(void Function()) setState,
  }) {
    

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            "Apply same time to all days",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          value: applyAll,
          onChanged: (v) => setState(() => applyAll = v ?? false),

        ),
        if (applyAll)
          Row(
            children: [
              TextButton(
                onPressed: () async {
                  final t = await _pickTime(context);
                  if (t != null) setState(() => bulkFrom = t);
                },
                child:
                    Text(bulkFrom == null ? "From" : bulkFrom!.format(context)),
              ),
              TextButton(
                onPressed: () async {
                  final t = await _pickTime(context);
                  if (t != null) setState(() => bulkTo = t);
                },
                child:
                    Text(bulkTo == null ? "To" : bulkTo!.format(context)),
              ),
              ElevatedButton(
                onPressed: bulkFrom != null && bulkTo != null
                    ? () {
                        setState(() {
                          for (final d in _weekDays) {
                            schedule[d] = {
                              "from": bulkFrom!.format(context),
                              "to": bulkTo!.format(context),
                             "closed": false,

                            };
                          }
                        });
                      }
                    : null,
                child: const Text("Apply"),
              ),
            ],
          ),
        const Divider(),
        ..._weekDays.map((day) {
          final d = schedule[day] ?? {};
          final closed = d["closed"] == true || d["closed"] == "true";

          return Column(
            children: [
              Row(
                children: [
                  SizedBox(width: 42, child: Text(day)),
              Checkbox(
                value: closed,
                onChanged: (v) {
                  setState(() {
                    schedule[day] = {
                      "closed": v == true,

                    };
                  });
                },
              ),


                  const Text("Closed"),
                ],
              ),
              if (!closed)
                Wrap(
  spacing: 8,
  runSpacing: 4,
  children: [
    TextButton(
      onPressed: () async {
        final t = await _pickTime(context);
        if (t != null) {
          setState(() {
            schedule[day] ??= {};
            schedule[day]!["from"] = t.format(context);
          });
        }
      },
      child: Text(d["from"] ?? "From"),
    ),
    TextButton(
      onPressed: () async {
        final t = await _pickTime(context);
        if (t != null) {
          setState(() {
            schedule[day] ??= {};
            schedule[day]!["to"] = t.format(context);
          });
        }
      },
      child: Text(d["to"] ?? "To"),
    ),
    TextButton(
      onPressed: () async {
        final t = await _pickTime(context);
        if (t != null) {
          setState(() {
            schedule[day]!["lunch_from"] = t.format(context);
          });
        }
      },
      child: const Text("Lunch from"),
    ),
    TextButton(
      onPressed: () async {
        final t = await _pickTime(context);
        if (t != null) {
          setState(() {
            schedule[day]!["lunch_to"] = t.format(context);
          });
        }
      },
      child: const Text("Lunch to"),
    ),
  ],
),

              const Divider(),
            ],
          );
        }).toList(),
      ],
    );
  }



  Future<void> _addServiceDialog() async {
    ServiceCatalogItem? selected;
    final price = TextEditingController();
    final minPrice = TextEditingController();
    final search = TextEditingController();

    String pricingUnit = "fixed";
    //Map<String, Map<String, String>> workingSchedule = {};
    Map<String, Map<String, dynamic>> workingSchedule = {};


    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Text("Add Service"),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: search,
                      decoration: const InputDecoration(
                        hintText: "Search services",
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: ServiceCatalog.items.map((item) {
                        final isSelected = selected?.id == item.id;
                        return InkWell(
                          onTap: () => setDialogState(() {
                            selected = item;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? item.color
                                    : ProviderTheme.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(item.icon,
                                    color: item.color, size: 18),
                                const SizedBox(width: 6),
                                Text(item.name),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),
                    TextField(
                      controller: price,
                      decoration:
                          const InputDecoration(labelText: "Fixed Price"),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: minPrice,
                      decoration:
                          const InputDecoration(labelText: "Minimum Charge"),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: pricingUnit,
                      decoration:
                          const InputDecoration(labelText: "Pricing"),
                      items: const [
                    DropdownMenuItem(value: "fixed", child: Text("Fixed")),
                    DropdownMenuItem(value: "per_hour", child: Text("Hourly")),

                      ],
                      onChanged: (v) =>
                          pricingUnit = v ?? pricingUnit,
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      "Working Hours (Per Day)",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    _workingScheduleEditor(
                      schedule: workingSchedule,
                      setState: setDialogState,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: selected == null
                      ? null
                      : () async {
                     await ServiceApi.addOrUpdateService({
                        "provider_id": widget.providerId,
                        "service_category_id": selected!.id,
                        "title": selected!.name,

                        // ⭐ NEW PRICING STRUCTURE
                        "pricing_unit": pricingUnit,
                        "pricing_type": pricingUnit == "per_hour" ? "hourly" : "fixed",
                        "fixed_price": pricingUnit == "fixed"
                            ? double.tryParse(price.text) ?? 0
                            : null,
                        "hourly_price": pricingUnit == "per_hour"
                            ? double.tryParse(price.text)
                            : null,

                        "minimum_charge": double.tryParse(minPrice.text),
                        "working_schedule": workingSchedule,
                      });

                          Navigator.pop(dialogCtx);
                          _load();
                        },
                  child: const Text("Add Service"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =======================
  // EDIT SERVICE
  // =======================
  Future<void> _editPricing(dynamic s) async {
    final price =
        TextEditingController(text: "${s["fixed_price"] ?? 0}");
   final minPrice =
    TextEditingController(text: "${s["minimum_charge"] ?? ""}");


    //Map<String, Map<String, String>> workingSchedule = {};
    Map<String, Map<String, dynamic>> workingSchedule = {};

    final raw = s["working_schedule"];
    if (raw is Map) {
      raw.forEach((day, times) {
        if (times is Map) {
         workingSchedule[day.toString()] = {
  "from": times["from"]?.toString() ?? "",
  "to": times["to"]?.toString() ?? "",
  "lunch_from": times["lunch_from"]?.toString() ?? "",
  "lunch_to": times["lunch_to"]?.toString() ?? "",
"closed": times["closed"] == true,



          };
        }
      });
    }

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, setState) {
          return AlertDialog(
            title: const Text("Edit Service"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: price,
                    decoration:
                        const InputDecoration(labelText: "Fixed Price"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: minPrice,
                    decoration:
                        const InputDecoration(labelText: "Minimum Charge"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Working Hours (Per Day)",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  _workingScheduleEditor(
                    schedule: workingSchedule,
                    setState: setState,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
          await ServiceApi.addOrUpdateService({
              "id": s["id"],
              "provider_id": widget.providerId,
              "service_category_id": s["service_category_id"],
              "title": s["title"],

              "pricing_type": s["pricing_type"] ?? "fixed",
              "fixed_price": double.tryParse(price.text) ?? 0,
              "minimum_charge": double.tryParse(minPrice.text),

              "working_schedule": workingSchedule,
            });

                  Navigator.pop(context);
                  _load();
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  // =======================
  // ENABLE / DELETE
  // =======================
  Future<void> _setActive(dynamic s, bool active) async {
    await ServiceApi.addOrUpdateService({
      "id": s["id"],
      "provider_id": widget.providerId,
      "service_category_id": s["service_category_id"],
      "title": s["title"],
      "fixed_price": s["fixed_price"] ?? 0,
     "minimum_charge": s["minimum_charge"],

      "pricing_type": s["pricing_type"] ?? "fixed",
      "working_schedule": s["working_schedule"],
      "is_active": active,
    });
    _load();
  }

  Future<void> _deleteService(dynamic s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Service"),
        content:
            const Text("Are you sure you want to delete this service?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete")),
        ],
      ),
    );

    if (ok == true) {
      await ServiceApi.deleteService(s["id"]);
      _load();
    }
  }

  // =======================
  // GRID
  // =======================
  Widget _buildGrid(bool active) {
    final list = _services.where((s) {
      final isActive = s["is_active"] ?? true;
      return active ? isActive : !isActive;
    }).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (_, i) {
        final s = list[i];
        final isActive = s["is_active"] ?? true;
        final todayBookings = s["today_bookings"] ?? 0;
        final cat = ServiceCatalog.byId(s["service_category_id"]);
        final color = cat?.color ?? ProviderTheme.primary;

        final isOpen = _isServiceOpenNow(s);
        final opensAt = _opensAtText(s);

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ServiceDetailsScreen(
                  providerId: widget.providerId,
                  serviceId: s["id"],
                  serviceTitle: s["title"],
                ),
              ),
            );
          },
          child: Opacity(
            opacity: isOpen ? 1 : 0.45,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ProviderTheme.border),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -4,
                    right: -6,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      onSelected: (v) {
                        if (v == "edit") {
                          _editPricing(s);
                        } else if (v == "toggle") {
                          _setActive(s, !isActive);
                        } else if (v == "delete") {
                          _deleteService(s);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: "edit",
                          child: Text("Edit Service"),
                        ),
                        PopupMenuItem(
                          value: "toggle",
                          child: Text(
                            isActive
                                ? "Disable Service"
                                : "Enable Service",
                          ),
                        ),
                        const PopupMenuItem(
                          value: "delete",
                          child: Text(
                            "Delete",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 34,
                        width: 34,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          cat?.icon ?? Icons.design_services,
                          size: 18,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        s["title"],
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                    Text(
                        _priceLabel(s),
                        style: const TextStyle(fontSize: 12),
                      ),

                      const SizedBox(height: 4),
                      Text(
                        isOpen ? "OPEN NOW" : "CLOSED",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color:
                              isOpen ? Colors.green : Colors.red,
                        ),
                      ),
                      if (!isOpen && opensAt != null)
                        Text(
                          "Opens at $opensAt",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        "Today: $todayBookings bookings",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =======================
  // UI
  // =======================
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ProviderTheme.themeData(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Services"),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "Active",),
              Tab(text: "Disabled"),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addServiceDialog,
          icon: const Icon(Icons.add_business),
          label: const Text("Add New Service"),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildGrid(true),
                  _buildGrid(false),
                ],
              ),
      ),
    );
  }

  String? _opensAtText(dynamic s) {
  final schedule = s["working_schedule"];
  if (schedule == null || schedule is! Map) return null;

  final weekday = DateTime.now().weekday;
  const days = {
    1: "Mon",
    2: "Tue",
    3: "Wed",
    4: "Thu",
    5: "Fri",
    6: "Sat",
    7: "Sun",
  };

  final today = days[weekday];
  return schedule[today]?["from"];
}
String _priceLabel(dynamic s) {
  final type = s["pricing_type"];

  if (type == "hourly") {
    return "₹${s["hourly_price"] ?? 0}/hr";
  }

  if (type == "per_30") {
    return "₹${s["per_30min_price"] ?? 0}/30m";
  }

  if (type == "visit") {
    return "Visit ₹${s["inspection_charge"] ?? 0}";
  }

  if (type == "hybrid") {
    return "₹${s["inspection_charge"] ?? 0} + ₹${s["hourly_price"] ?? 0}/hr";
  }

  return "₹${s["fixed_price"] ?? 0}";
}


}




import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../api/service_api.dart';

class ProviderEarningsDashboard extends StatefulWidget {
  final String providerId;

  const ProviderEarningsDashboard({super.key, required this.providerId});

  @override
  State<ProviderEarningsDashboard> createState() => _ProviderEarningsDashboardState();
}

class _ProviderEarningsDashboardState extends State<ProviderEarningsDashboard> {
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
      final res = await ServiceApi.getProviderEarningsDashboard(widget.providerId);
      setState(() => _data = res);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),
      appBar: AppBar(title: const Text("Earnings Dashboard")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text("Failed to load dashboard"))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _headerCards(),
                      const SizedBox(height: 20),
                      _dailyChart(),
                      const SizedBox(height: 20),
                      _weeklyChart(),
                      const SizedBox(height: 20),
                      _categoryPie(),
                      const SizedBox(height: 20),
                      _statsPanel(),
                      const SizedBox(height: 20),
                      _financialBreakdown(),
                    ],
                  ),
                ),
    );
  }

  Widget _headerCards() {
    final cards = _data!["cards"];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _card("Today", cards["today"]),
        _card("This Week", cards["week"]),
        _card("This Month", cards["month"]),
        _card("Lifetime", cards["lifetime"]),
      ],
    );
  }

  Widget _card(String title, num amount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff6A11CB), Color(0xff2575FC)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const Spacer(),
          Text(
            "₹${amount.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dailyChart() {
    final daily = Map<String, dynamic>.from(_data!["charts"]["daily"]);

    final spots = <FlSpot>[];
    int i = 0;
    daily.forEach((k, v) {
      spots.add(FlSpot(i.toDouble(), (v as num).toDouble()));
      i++;
    });

    return _panel(
      title: "Daily Earnings",
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                barWidth: 3,
                dotData: FlDotData(show: false),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _weeklyChart() {
    final weekly = Map<String, dynamic>.from(_data!["charts"]["weekly"]);

    final bars = <BarChartGroupData>[];
    int i = 0;

    weekly.forEach((k, v) {
      bars.add(
        BarChartGroupData(x: i, barRods: [BarChartRodData(toY: (v as num).toDouble())]),
      );
      i++;
    });

    return _panel(
      title: "Weekly Performance",
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: bars,
          ),
        ),
      ),
    );
  }

  Widget _categoryPie() {
    final category = Map<String, dynamic>.from(_data!["charts"]["category"]);

    final sections = <PieChartSectionData>[];

    category.forEach((k, v) {
      sections.add(
        PieChartSectionData(
          value: (v as num).toDouble(),
          title: k,
        ),
      );
    });

    return _panel(
      title: "Category Earnings",
      child: SizedBox(
        height: 220,
        child: PieChart(
          PieChartData(sections: sections),
        ),
      ),
    );
  }

  Widget _statsPanel() {
    final stats = _data!["stats"];

    return _panel(
      title: "Performance Stats",
      child: Column(
        children: [
          _stat("Completed Jobs", stats["completed_jobs"]),
          _stat("Avg per Job", stats["avg_per_job"]),
          _stat("Best Day", stats["highest_day"]["date"] ?? "-"),
        ],
      ),
    );
  }

  Widget _financialBreakdown() {
    final f = _data!["financial"];

    return _panel(
      title: "Financial Breakdown",
      child: Column(
        children: [
          _stat("Gross", f["gross_earnings"]),
          _stat("Platform Fee", f["platform_fee"]),
          _stat("Tax", f["tax"]),
          _stat("Refund Loss", f["refund_loss"]),
          _stat("Net Payout", f["net_payout"]),
        ],
      ),
    );
  }

  Widget _panel({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _stat(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

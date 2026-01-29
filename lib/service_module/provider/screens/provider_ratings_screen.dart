import 'package:flutter/material.dart';
import '../api/service_api.dart';
import '../utils/provider_theme.dart';
import '../utils/ui_helpers.dart';

class ProviderRatingsScreen extends StatefulWidget {
  final String providerId;
  const ProviderRatingsScreen({super.key, required this.providerId});

  @override
  State<ProviderRatingsScreen> createState() => _ProviderRatingsScreenState();
}

class _ProviderRatingsScreenState extends State<ProviderRatingsScreen> {
  bool _loading = true;
  double _overall = 0;
  List<dynamic> _reviews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ServiceApi.ratings(widget.providerId);
      setState(() {
        _overall = (res["overall_rating"] ?? 0).toDouble();
        _reviews = res["reviews"] ?? [];
      });
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
          title: const Text("Ratings & Reviews"),
          actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Card(
                      child: ListTile(
                        title: const Text("Overall Rating", style: TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: const Text("View-only. Provider cannot edit/delete reviews."),
                        trailing: Text(_overall.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _reviews.isEmpty
                          ? const Center(child: Text("No reviews yet"))
                          : ListView.builder(
                              itemCount: _reviews.length,
                              itemBuilder: (_, i) {
                                final r = _reviews[i];
                                return Card(
                                  child: ListTile(
                                    title: Text("⭐ ${(r["rating"] ?? 0).toDouble().toStringAsFixed(1)}"),
                                    subtitle: Text(r["review"] ?? ""),
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

import 'package:flutter/material.dart';
import '../utils/provider_theme.dart';
import 'availability_calendar_screen.dart';
import 'provider_bookings_screen.dart';

class ServiceDetailsScreen extends StatelessWidget {
  final String providerId;
  final String serviceId;
  final String serviceTitle;

  const ServiceDetailsScreen({
    super.key,
    required this.providerId,
    required this.serviceId,
    required this.serviceTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ProviderTheme.themeData(),
      child: Scaffold(
        appBar: AppBar(title: Text(serviceTitle)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Charges Overview", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      SizedBox(height: 10),
                      _InfoRow(label: "Minimum Charge", value: "₹ (from backend service)"),
                      _InfoRow(label: "Fixed Price", value: "₹ (from backend service)"),
                      _InfoRow(label: "Service Charge", value: "Platform commission applies"),
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
                    children: const [
                      Text("Weekly Availability Summary", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      SizedBox(height: 10),
                      Text("Mon–Fri • 09:00 - 18:00", style: TextStyle(color: ProviderTheme.subText)),
                      Text("Slot size: 30 minutes", style: TextStyle(color: ProviderTheme.subText)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_month),
                      label: const Text("Open Calendar"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AvailabilityCalendarScreen(providerId: providerId),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.list_alt),
                      label: const Text("Open Bookings"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProviderBookingsScreen(providerId: providerId),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: ProviderTheme.subText)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

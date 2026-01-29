import 'package:flutter/material.dart';
import '../utils/provider_theme.dart';
import '../utils/service_catalog.dart';
import 'my_services_screen.dart';
import 'provider_bookings_screen.dart';

class ProviderHomeDashboard extends StatelessWidget {
  final String providerId;
  final String providerName;
  final String role; // provider/requester
  final String serviceCategoryId;

  const ProviderHomeDashboard({
    super.key,
    required this.providerId,
    required this.providerName,
    required this.role,
    required this.serviceCategoryId,
  });

  @override
  Widget build(BuildContext context) {
    final cat = ServiceCatalog.byId(serviceCategoryId);

    return Theme(
      data: ProviderTheme.themeData(),
      child: Scaffold(
        appBar: AppBar(
          title: Text("Service Dashboard"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: (cat?.color ?? ProviderTheme.primary).withOpacity(0.15),
                    child: Icon(cat?.icon ?? Icons.work, color: cat?.color ?? ProviderTheme.primary),
                  ),
                  title: Text(providerName, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text("${cat?.name ?? "Service"} • Role: $role"),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _GridCard(
                      title: "My Services",
                      icon: Icons.grid_view_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MyServicesScreen(providerId: providerId, serviceCategoryId: serviceCategoryId),
                          ),
                        );
                      },
                    ),
                    _GridCard(
                      title: "Service Requests",
                      icon: Icons.notifications_active_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProviderBookingsScreen(providerId: providerId),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _GridCard({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: ProviderTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.apps, size: 28, color: ProviderTheme.primary),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../utils/provider_theme.dart';
import '../utils/service_catalog.dart';

import '../utils/service_notification_realtime.dart';
import 'customer_my_bookings_screen.dart';
import 'my_services_screen.dart';
import 'provider_bookings_screen.dart';
import 'provider_earnings_dashboard.dart';
import '../requests/request_service_home.dart';
import 'service_notification_screen.dart';
import 'service_wallet_screen.dart';
import 'provider_inbox_screen.dart';

class ProviderHomeDashboard extends StatefulWidget {
  final String providerId;
  final String providerName;
  final String role;
  final String serviceCategoryId;

  const ProviderHomeDashboard({
    super.key,
    required this.providerId,
    required this.providerName,
    required this.role,
    required this.serviceCategoryId,
  });

  @override
  State<ProviderHomeDashboard> createState() =>
      _ProviderHomeDashboardState();
}

class _ProviderHomeDashboardState
    extends State<ProviderHomeDashboard> {

  ////////////////////////////////////////////////////////////
  /// LOGOUT
  ////////////////////////////////////////////////////////////

  Future<bool> _confirmLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context, true);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/role_select',
                (route) => false,
              );
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  ////////////////////////////////////////////////////////////
  /// UI
  ////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    final cat = ServiceCatalog.byId(widget.serviceCategoryId);

    return Theme(
      data: ProviderTheme.themeData(),
      child: WillPopScope(
        onWillPop: () async => await _confirmLogout(context),
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Service Dashboard"),
            automaticallyImplyLeading: false,
            actions: [

              ////////////////////////////////////////////////////////////
              /// 🔔 REALTIME NOTIFICATION BELL
              ////////////////////////////////////////////////////////////

              StreamBuilder<int>(
                stream: ServiceNotificationRealtime
                    .unreadCountStream(widget.providerId),
                builder: (_, snapshot) {

                  final unreadCount = snapshot.data ?? 0;

                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ServiceNotificationScreen(
                                providerId: widget.providerId,
                              ),
                            ),
                          );
                        },
                      ),

                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),

              ////////////////////////////////////////////////////////////
              /// LOGOUT
              ////////////////////////////////////////////////////////////

              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _confirmLogout(context),
              )
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                ////////////////////////////////////////////////////////////
                /// PROFILE HEADER
                ////////////////////////////////////////////////////////////

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor:
                            (cat?.color ?? ProviderTheme.primary)
                                .withOpacity(0.15),
                        child: Icon(
                          cat?.icon ?? Icons.work,
                          color: cat?.color ?? ProviderTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.providerName,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                ////////////////////////////////////////////////////////////
                /// PENDING BANNER
                ////////////////////////////////////////////////////////////

                _PendingBanner(),

                const SizedBox(height: 20),

                ////////////////////////////////////////////////////////////
                /// GRID ACTIONS
                ////////////////////////////////////////////////////////////

                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [

                      _ActionCard(
                        title: "Manage Requests",
                        icon: Icons.assignment_turned_in,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProviderBookingsScreen(
                                providerId: widget.providerId,
                              ),
                            ),
                          );
                        },
                      ),

                      _ActionCard(
                        title: "My Services",
                        icon: Icons.grid_view_rounded,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MyServicesScreen(
                                providerId: widget.providerId,
                                serviceCategoryId:
                                    widget.serviceCategoryId,
                              ),
                            ),
                          );
                        },
                      ),

                      _ActionCard(
                        title: "Request Service",
                        icon: Icons.add_circle_outline,
                        color: Colors.teal,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RequestServiceHome(),
                            ),
                          );
                        },
                      ),

                      _ActionCard(
                        title: "Wallet",
                        icon: Icons.account_balance_wallet,
                        color: Colors.indigo,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ServiceWalletScreen(),
                            ),
                          );
                        },
                      ),

                      _ActionCard(
                        title: "Earnings",
                        icon: Icons.bar_chart_rounded,
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProviderEarningsDashboard(
                                providerId: widget.providerId,
                              ),
                            ),
                          );
                        },
                      ),

                      _ActionCard(
                        title: "My Bookings",
                        icon: Icons.book_online,
                        color: Colors.purple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const CustomerMyBookingsScreen(),
                            ),
                          );
                        },
                      ),

                      _ActionCard(
                      title: "Inbox",
                      icon: Icons.chat_bubble_outline_sharp,
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProviderInboxScreen(),
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
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// Pending Banner
////////////////////////////////////////////////////////////

class _PendingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: const [
          Icon(Icons.notifications_active, color: Colors.orange),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "You have pending service requests",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// Action Card
////////////////////////////////////////////////////////////

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

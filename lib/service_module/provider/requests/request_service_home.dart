import 'package:flutter/material.dart';
import '../utils/provider_theme.dart';
import '../utils/service_catalog.dart';
import 'request_service_list.dart';

class RequestServiceHome extends StatefulWidget {
  const RequestServiceHome({super.key});

  @override
  State<RequestServiceHome> createState() => _RequestServiceHomeState();
}

class _RequestServiceHomeState extends State<RequestServiceHome> {
  bool isGrid = true;
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filteredServices = ServiceCatalog.items.where((cat) {
      return cat.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Theme(
      data: ProviderTheme.themeData(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Request a Service"),
          actions: [
            IconButton(
              icon: Icon(isGrid ? Icons.view_list : Icons.grid_view),
              tooltip: isGrid ? "Switch to List View" : "Switch to Grid View",
              onPressed: () {
                setState(() {
                  isGrid = !isGrid;
                });
              },
            )
          ],
        ),

        body: Column(
          children: [

            /// 🔎 Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search services...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    searchQuery = val;
                  });
                },
              ),
            ),

            /// 📦 Service List / Grid
            Expanded(
              child: isGrid
                  ? GridView.builder(
                      padding: const EdgeInsets.all(16),
                      physics: const BouncingScrollPhysics(), // smooth scrolling
                      itemCount: filteredServices.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                      ),
                      itemBuilder: (context, index) {
                        final cat = filteredServices[index];
                        return _serviceGridItem(context, cat);
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      physics: const BouncingScrollPhysics(), // smooth scrolling
                      itemCount: filteredServices.length,
                      itemBuilder: (context, index) {
                        final cat = filteredServices[index];
                        return _serviceListItem(context, cat);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🟦 Grid Item
  Widget _serviceGridItem(BuildContext context, dynamic cat) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openService(context, cat),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(cat.icon, size: 38, color: cat.color),
            const SizedBox(height: 10),
            Text(
              cat.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  /// 📋 List Item
  Widget _serviceListItem(BuildContext context, dynamic cat) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cat.color.withOpacity(0.15),
          child: Icon(cat.icon, color: cat.color),
        ),
        title: Text(
          cat.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _openService(context, cat),
      ),
    );
  }

  /// 🚀 Navigation
  void _openService(BuildContext context, dynamic cat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestServiceList(categoryId: cat.id),
      ),
    );
  }
}

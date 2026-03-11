import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../services/session_manager.dart';
import 'add_items_screen.dart';

class CreateShopScreen extends StatefulWidget {
  const CreateShopScreen({super.key});

  @override
  State<CreateShopScreen> createState() => _CreateShopScreenState();
}

class _CreateShopScreenState extends State<CreateShopScreen> {
  final _shopNameController = TextEditingController();
  bool _isLoading = false;

  final String baseUrl =
      "https://grocery-backend-956424262985.asia-south1.run.app";

  Future<void> _createShop() async {
    final name = _shopNameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Enter shop name")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔥 ALWAYS GET FROM SESSION MANAGER
      final token = await SessionManager.getAuthToken();
      final shopkeeperId = await SessionManager.getShopkeeperId();

    

      if (token == null || token.isEmpty || shopkeeperId == null) {
        throw Exception("User not logged in");
      }

      final response = await http.post(
        Uri.parse('$baseUrl/create_shop'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "name": name,
          "address": "Default Address",
          "contact": "0000000000"
      
        }),
      );

    

      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {

        final shop = data['shop'];

        // 🔥 SAVE SHOP IN SESSION MANAGER
        await SessionManager.setShopId(shop['id']);
        await SessionManager.setShopInfo(shop['id'], shop['name']);

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Shop Created!")));

        // 👉 go to Add Items
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AddItemsScreen()),
        );

      } else {
        throw Exception(data['message'] ?? "Failed to create shop");
      }

    } catch (e) {
      print("CREATE SHOP ERROR: $e");

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }

    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Your Shop")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text("Give your new shop a name",
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),

            TextField(
              controller: _shopNameController,
              decoration: const InputDecoration(
                labelText: "Shop Name",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createShop,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create Shop",
                        style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

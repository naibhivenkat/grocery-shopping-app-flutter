import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import '../services/invoice_html_service.dart';
import 'invoice_viewer_screen.dart';
import 'invoice_history_screen.dart';

class SelectedItem {
  final String name;
  final int quantity;

  SelectedItem({
    required this.name,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
      };

  @override
  String toString() => '$name - $quantity';
}

class ExcelItemSelectionScreen extends StatefulWidget {
  const ExcelItemSelectionScreen({super.key});

  @override
  State<ExcelItemSelectionScreen> createState() =>
      _ExcelItemSelectionScreenState();
}

class _ExcelItemSelectionScreenState extends State<ExcelItemSelectionScreen> {
  // ============================================================
  // LOCAL EXCEL FILE PATH (ASSET PATH)
  // ============================================================

  static const String excelAssetPath = 'assets/data/Pooje_Item_list.xlsx';

  List<String> allItems = [];
  List<String> filteredItems = [];

  final Map<String, TextEditingController> quantityControllers = {};
  final TextEditingController searchController = TextEditingController();

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadExcelData();

    searchController.addListener(() {
      filterItems(searchController.text);
    });
  }

  // ============================================================
  // LOAD EXCEL FROM LOCAL ASSET
  // ============================================================
// ============================================================
// CATEGORY SUPPORT
// ============================================================

Map<String, List<String>> categoryItems = {};
List<String> categories = [];
String? selectedCategory;

// ============================================================
// LOAD EXCEL FROM ALL SHEETS
// ============================================================

Future<void> loadExcelData() async {
  try {
    final ByteData data = await rootBundle.load(excelAssetPath);
    final Uint8List bytes = data.buffer.asUint8List();

    final decoder = SpreadsheetDecoder.decodeBytes(
      bytes,
      update: false,
    );

    if (decoder.tables.isEmpty) {
      throw Exception('Excel file contains no sheets.');
    }

    // Your file has one sheet (usually "Sheet1")
    final table = decoder.tables.values.first;

    final Map<String, List<String>> loadedCategoryItems = {};
    final Set<String> allUniqueItems = {};

    // Determine maximum number of columns
    int maxColumns = 0;
    for (final row in table.rows) {
      if (row.length > maxColumns) {
        maxColumns = row.length;
      }
    }

    // Read each column
    for (int col = 0; col < maxColumns; col++) {
      String? categoryName;
      final List<String> items = [];

      // Read all rows in this column
      for (int rowIndex = 0; rowIndex < table.rows.length; rowIndex++) {
        final row = table.rows[rowIndex];

        if (col >= row.length) continue;

        final cell = row[col];
        if (cell == null) continue;

        final value = cell.toString().trim();
        if (value.isEmpty) continue;

        // First non-empty cell = category name
        if (categoryName == null) {
          categoryName = value;
          continue;
        }

        // Remaining cells = items
        items.add(value);
        allUniqueItems.add(value);
      }

      // Save category if it has items
      if (categoryName != null && items.isNotEmpty) {
        loadedCategoryItems[categoryName] = items;
      }
    }

    // Create quantity controllers for all items
    for (final item in allUniqueItems) {
      quantityControllers[item] ??= TextEditingController();
    }

    final List<String> loadedCategories =
        loadedCategoryItems.keys.toList();

    if (loadedCategories.isEmpty) {
      throw Exception(
        'No categories or items found in Excel columns.',
      );
    }

    if (!mounted) return;

    setState(() {
      categoryItems = loadedCategoryItems;
      categories = loadedCategories;
      selectedCategory = categories.first;

      allItems = List.from(
        categoryItems[selectedCategory] ?? [],
      );

      filteredItems = List.from(allItems);

      isLoading = false;
      errorMessage = null;
    });
  } catch (e, stackTrace) {
    debugPrint('Excel loading error: $e');
    debugPrint('$stackTrace');

    if (!mounted) return;

    setState(() {
      errorMessage = 'Failed to load Excel file:\n$e';
      isLoading = false;
    });
  }
}


  // ============================================================
  // SEARCH FILTER
  // ============================================================
void filterItems(String query) {
  final List<String> baseItems =
      categoryItems[selectedCategory] ?? [];

  setState(() {
    allItems = List.from(baseItems);

    if (query.trim().isEmpty) {
      filteredItems = List.from(baseItems);
    } else {
      final q = query.toLowerCase();
      filteredItems = baseItems
          .where(
            (item) => item.toLowerCase().contains(q),
          )
          .toList();
    }
  });
}
  // ============================================================
  // GET SELECTED ITEMS
  // ============================================================

List<SelectedItem> getSelectedItems() {
  final List<SelectedItem> selected = [];

  // Iterate through ALL items across ALL categories
  for (final entry in quantityControllers.entries) {
    final String itemName = entry.key;
    final TextEditingController controller = entry.value;

    final String text = controller.text.trim();

    // Skip empty quantities
    if (text.isEmpty) continue;

    // Parse quantity
    final int? qty = int.tryParse(text);

    // Skip invalid or zero quantities
    if (qty == null || qty <= 0) continue;

    // Add selected item
    selected.add(
      SelectedItem(
        name: itemName,
        quantity: qty,
      ),
    );
  }

  // Optional: sort alphabetically for consistent display
  selected.sort(
    (a, b) => a.name.compareTo(b.name),
  );

  return selected;
}

  // ============================================================
  // CONFIRM SELECTION
  // ============================================================
  
 void confirmSelection() async {
  final selected = getSelectedItems();

  if (selected.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter quantity for at least one item.'),
      ),
    );
    return;
  }

  // Create editable copy of selected items
  final List<SelectedItem> reviewItems = selected
      .map(
        (e) => SelectedItem(
          name: e.name,
          quantity: e.quantity,
        ),
      )
      .toList();

  final String? action = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 500,
                maxHeight: 600,
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shopping_cart_checkout,
                          color: Colors.green,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Selected Items (${reviewItems.length})',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(),

                  // Editable Item List
                  Expanded(
                    child: reviewItems.isEmpty
                        ? const Center(
                            child: Text(
                              'No items selected.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: reviewItems.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 16),
                            itemBuilder: (context, index) {
                              final item = reviewItems[index];

                              return Row(
                                children: [
                                  // Serial Number
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor:
                                        const Color.fromARGB(255, 15, 15, 15).withOpacity(0.1),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // Item Name
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),

                                  // Minus Button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setDialogState(() {
                                        final current = reviewItems[index];

                                        if (current.quantity > 1) {
                                          reviewItems[index] = SelectedItem(
                                            name: current.name,
                                            quantity:
                                                current.quantity - 1,
                                          );
                                        } else {
                                          reviewItems.removeAt(index);
                                        }
                                      });
                                    },
                                  ),

                                  // Quantity Display
                                  Container(
                                    width: 40,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),

                                  // Plus Button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.green,
                                    ),
                                    onPressed: () {
                                      setDialogState(() {
                                        final current = reviewItems[index];
                                        reviewItems[index] = SelectedItem(
                                          name: current.name,
                                          quantity:
                                              current.quantity + 1,
                                        );
                                      });
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Summary
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Total Selected Items: ${reviewItems.length}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    children: [
                      // Return to Excel Screen
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(dialogContext, 'modify');
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Modify'),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Final Confirm
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: reviewItems.isEmpty
                              ? null
                              : () {
                                  Navigator.pop(
                                    dialogContext,
                                    'confirm',
                                  );
                                },
                          icon: const Icon(Icons.check),
                          label: const Text('Confirm Order'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  // Return to Excel screen for manual editing
  if (action == 'modify') {
    return;
  }

// Final confirmation: generate HTML invoice and open preview
if (action == 'confirm') {
  try {
    // Generate and save HTML invoice locally
    final htmlFile = await generateInvoiceHtml(reviewItems);

    if (!mounted) return;

    // Open invoice preview inside the Excel flow
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvoiceViewerScreen(
          htmlFilePath: htmlFile.path,
        ),
      ),
    );

    // Optional success message
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invoice saved successfully.'),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to generate invoice: $e'),
      ),
    );
  }
}

} 


  @override
  void dispose() {
    searchController.dispose();

    for (final controller in quantityControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ಐಟಂಗಳನ್ನು ಆಯ್ಕೆ ಮಾಡಿ'),
actions: [
  IconButton(
    icon: const Icon(Icons.history),
    tooltip: 'Invoice History',
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const InvoiceHistoryScreen(),
        ),
      );
    },
  ),
  IconButton(
    icon: const Icon(Icons.check),
    onPressed: confirmSelection,
  ),
],
      ),
      body: buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: confirmSelection,
        icon: const Icon(Icons.check),
        label: const Text('Confirm'),
      ),
    );
  }

 Widget buildBody() {
  if (isLoading) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  if (errorMessage != null) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          errorMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  if (categories.isEmpty) {
    return const Center(
      child: Text('No categories found in Excel file.'),
    );
  }

  return Column(
    children: [
      // ==========================================================
      // SEARCH BOX
      // ==========================================================
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: 'Search (Kannada or English)',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
      ),

      // ==========================================================
      // CATEGORY DROPDOWN (EXCEL SHEET SELECTOR)
      // ==========================================================
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonFormField<String>(
          value: selectedCategory,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Select Category',
            prefixIcon: Icon(Icons.category),
            border: OutlineInputBorder(),
          ),
          items: categories.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(
                category,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              selectedCategory = value;
            });

            // Reload items for the selected category
            filterItems(searchController.text);
          },
        ),
      ),

      const SizedBox(height: 8),

      // ==========================================================
      // CATEGORY + ITEM COUNT INFO
      // ==========================================================
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Category: ${selectedCategory ?? ''}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              'Items: ${filteredItems.length}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 8),

      // ==========================================================
      // ITEMS LIST
      // ==========================================================
      Expanded(
        child: filteredItems.isEmpty
            ? const Center(
                child: Text(
                  'No items found in this category.',
                ),
              )
            : ListView.builder(
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  final controller =
                      quantityControllers[item]!;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Item Name
                          Expanded(
                            flex: 3,
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Quantity Input
                          SizedBox(
                            width: 90,
                            child: TextField(
                              controller: controller,
                              keyboardType:
                                  TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration:
                                  const InputDecoration(
                                labelText: 'Qty',
                                border:
                                    OutlineInputBorder(),
                                isDense: true,
                              ),
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
  );
}}
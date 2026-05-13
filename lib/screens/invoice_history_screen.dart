import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'invoice_viewer_screen.dart';

class InvoiceHistoryScreen extends StatefulWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  State<InvoiceHistoryScreen> createState() =>
      _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState
    extends State<InvoiceHistoryScreen> {
  List<FileSystemEntity> invoiceFiles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadInvoices();
  }

  Future<void> loadInvoices() async {
    try {
      final directory = await getApplicationDocumentsDirectory();

      final files = directory
          .listSync()
          .where(
            (file) =>
                file.path.endsWith('.html') &&
                file.path.contains('invoice_'),
          )
          .toList();

      // Newest first
      files.sort(
        (a, b) => b.path.compareTo(a.path),
      );

      if (!mounted) return;

      setState(() {
        invoiceFiles = files;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  String getFileName(String path) {
    return path.split('/').last;
  }

  String formatDate(FileSystemEntity file) {
    try {
      final stat = file.statSync();
      return stat.modified.toString();
    } catch (_) {
      return '';
    }
  }

  Future<void> deleteInvoice(FileSystemEntity file) async {
    await File(file.path).delete();

    if (!mounted) return;

    await loadInvoices();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invoice deleted successfully.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice History'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : invoiceFiles.isEmpty
              ? const Center(
                  child: Text('No saved invoices found.'),
                )
              : ListView.builder(
                  itemCount: invoiceFiles.length,
                  itemBuilder: (context, index) {
                    final file = invoiceFiles[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.receipt_long,
                          color: Colors.indigo,
                        ),
                        title: Text(
                          getFileName(file.path),
                        ),
                        subtitle: Text(
                          formatDate(file),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'delete') {
                              await deleteInvoice(file);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  InvoiceViewerScreen(
                                htmlFilePath:
                                    file.path,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
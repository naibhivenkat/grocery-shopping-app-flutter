import 'package:flutter/material.dart';
import 'provider_theme.dart';

class UIHelpers {
  static void showSnack(BuildContext context, String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade700 : ProviderTheme.primary,
      ),
    );
  }

  static Future<bool> confirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String yes = "Yes",
    String no = "No",
  }) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(no),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(yes),
          ),
        ],
      ),
    );
    return res ?? false;
  }
}

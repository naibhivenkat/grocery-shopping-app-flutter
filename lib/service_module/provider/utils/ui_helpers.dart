import 'package:flutter/material.dart';
import 'provider_theme.dart';

class UIHelpers {

  // ───────────────── SNACKBAR ─────────────────

  static void showSnack(BuildContext context, String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade700 : ProviderTheme.primary,
      ),
    );
  }

  // ───────────────── CONFIRM DIALOG ─────────────────

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

  // ───────────────── LOADING DIALOG (NEW) ─────────────────

  static void showLoading(BuildContext context, {String message = "Please wait..."}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }

  static void hideLoading(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  // ───────────────── ERROR DIALOG (NEW) ─────────────────

  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ───────────────── SUCCESS DIALOG (NEW) ─────────────────

  static void showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Success"),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ───────────────── INPUT DIALOG (COUPON / TEXT ENTRY) ─────────────────

static Future<String?> showInputDialog(
  BuildContext context,
  String title, {
  String hint = "",
  String confirmText = "Apply",
}) async {
  final controller = TextEditingController();

  final res = await showDialog<String>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () =>
              Navigator.pop(dialogCtx, controller.text.trim()),
          child: Text(confirmText),
        ),
      ],
    ),
  );

  return res;
}

}

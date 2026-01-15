import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InvoiceViewScreen extends StatefulWidget {
  final String orderId;

  const InvoiceViewScreen({super.key, required this.orderId});

  @override
  State<InvoiceViewScreen> createState() => _InvoiceViewScreenState();
}

class _InvoiceViewScreenState extends State<InvoiceViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  // Base URL (Same as your Kotlin code)
  final String baseUrl = "https://grocery-backend-956424262985.asia-south1.run.app";

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
            
            // 🛠️ JS BRIDGE: This makes your existing HTML button work in Flutter!
            // We redefine 'AndroidApp.goBackToApp' to call Flutter's channel instead.
            _controller.runJavaScript('''
              window.AndroidApp = {
                goBackToApp: function() {
                  FlutterChannel.postMessage('back');
                }
              };
            ''');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint("WebView Error: ${error.description}");
          },
        ),
      )
      // ✅ Add the Channel to listen for the message
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'back') {
            Navigator.pop(context); // Close screen
          }
        },
      )
      ..loadRequest(Uri.parse('$baseUrl/api/invoice_html/${widget.orderId}'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Invoice"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
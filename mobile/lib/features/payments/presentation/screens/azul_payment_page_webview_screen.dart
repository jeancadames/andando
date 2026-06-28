import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AzulPaymentPageWebViewScreen extends StatefulWidget {
  const AzulPaymentPageWebViewScreen({
    super.key,
    required this.url,
    required this.headers,
  });

  final String url;
  final Map<String, String> headers;

  @override
  State<AzulPaymentPageWebViewScreen> createState() =>
      _AzulPaymentPageWebViewScreenState();
}

class _AzulPaymentPageWebViewScreenState
    extends State<AzulPaymentPageWebViewScreen> {
  late final WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
            final url = request.url;

            if (url.contains('/payment-methods?status=')) {
              final uri = Uri.parse(url);
              final status = uri.queryParameters['status'];

              Navigator.pop(context, status == 'approved' || status == 'success');

              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        Uri.parse(widget.url),
        headers: widget.headers,
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar tarjeta'),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
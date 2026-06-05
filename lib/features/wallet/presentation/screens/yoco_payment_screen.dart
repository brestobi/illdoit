import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:go_router/go_router.dart';

class YocoPaymentScreen extends StatefulWidget {
  final String checkoutUrl;
  final String callbackUrl;

  const YocoPaymentScreen({
    super.key,
    required this.checkoutUrl,
    required this.callbackUrl,
  });

  @override
  State<YocoPaymentScreen> createState() => _YocoPaymentScreenState();
}

class _YocoPaymentScreenState extends State<YocoPaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('Page started loading: $url');
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            debugPrint('Page finished loading: $url');
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            debugPrint('WebView error: ${error.description}');
            setState(() {
              _isLoading = false;
              _errorMessage = 'Failed to load payment page.';
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('Navigating to: ${request.url}');
            if (request.url.startsWith(widget.callbackUrl)) {
              debugPrint('Callback URL detected! Closing.');
              context.pop(true); // Return success
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(false), // Return cancel
        ),
      ),
      body: _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        _isLoading = true;
                      });
                      _controller.reload();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading) const Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final Function(bool success) onPaymentResult;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.onPaymentResult,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    if (kIsWeb) {
      // For Web, we can't use WebView easily due to CORS/Frame restrictions on banking sites.
      // We will launch the URL in a new tab/window.
      _launchWebUrl();
    } else {
      // For Mobile, use WebView
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() => _isLoading = true);
            },
            onPageFinished: (String url) {
              setState(() => _isLoading = false);
            },
            onNavigationRequest: (NavigationRequest request) {
              debugPrint('Navigating to: ${request.url}');
              if (request.url.contains('vnp_ResponseCode=00')) {
                // Success
                widget.onPaymentResult(true);
                Navigator.pop(context);
                return NavigationDecision.prevent;
              } else if (request.url.contains('payment/vnpay/return') && !request.url.contains('vnp_ResponseCode=00')) {
                // Failed or Cancelled
                 widget.onPaymentResult(false);
                 Navigator.pop(context);
                 return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.paymentUrl));
    }
  }

  Future<void> _launchWebUrl() async {
    final Uri url = Uri.parse(widget.paymentUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Không thể mở liên kết thanh toán')),
         );
         Navigator.pop(context);
       }
    } else {
      // Assuming success if launched, user will return manually or verify later
      // In a real web app, we would listen to route changes or return URL parameters on app reload.
      // For this demo, we can just pop and ask user to check balance.
      if (mounted) {
         Navigator.pop(context);
         widget.onPaymentResult(true); // Tentative success, prompt user to refresh
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán VNPay')),
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

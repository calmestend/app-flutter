import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io' show Platform;
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String htmlContent;

  const WebViewScreen({
    Key? key,
    required this.url,
    required this.htmlContent,
  }) : super(key: key);

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    // Crear los parámetros específicos de la plataforma
    late final PlatformWebViewControllerCreationParams params;
    if (Platform.isAndroid) {
      params = AndroidWebViewControllerCreationParams();
    } else if (Platform.isIOS) {
      params = WebKitWebViewControllerCreationParams();
    } else {
      throw UnsupportedError('Plataforma no soportada');
    }

    // Crear el controlador con los parámetros de la plataforma
    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    // Configurar el controlador
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() {
                isLoading = false;
              });
            }
          },
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
            });
            print("Page started loading: $url");
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
            print("Page finished loading: $url");
          },
          onNavigationRequest: (NavigationRequest request) {
            print("Navigation request: ${request.url}");
            if (request.url.contains('paypal/success') ||
                request.url.contains('api/paypal/success')) {
              Navigator.of(context).pop('success');
              return NavigationDecision.prevent;
            } else if (request.url.contains('paypal/cancel') ||
                request.url.contains('api/paypal/cancel')) {
              Navigator.of(context).pop('cancel');
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            print("Web resource error: ${error.description}");
          },
        ),
      )
      ..loadHtmlString(widget.htmlContent);

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayPal Payment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop('cancel'),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'dart:io' show Platform;

class ShoppingCartScreen extends StatefulWidget {
  final int userId = 8;

  const ShoppingCartScreen({Key? key}) : super(key: key);

  @override
  _ShoppingCartScreenState createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  List<dynamic> products = [];
  String? paymentUrl;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCartProducts();
  }

  Future<void> _fetchCartProducts() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http
          .get(Uri.parse('http://10.0.2.2:8000/cart/${widget.userId}'));

      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            products = json.decode(response.body);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load cart products')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _addProduct(int productId) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/cart/add/${widget.userId}/$productId'),
        body: json.encode({'quantity': 1}),
        headers: {'Content-Type': 'application/json'},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          _fetchCartProducts();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add product')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e')),
        );
      }
    }
  }

  Future<void> _removeProduct(int productId) async {
    try {
      final response = await http.post(
        Uri.parse(
            'http://10.0.2.2:8000/cart/remove/${widget.userId}/$productId'),
        body: json.encode({'quantity': 1}),
        headers: {'Content-Type': 'application/json'},
      );

      if (mounted) {
        if (response.statusCode == 200) {
          _fetchCartProducts();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to remove product')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e')),
        );
      }
    }
  }

  Future<void> _createPayment() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/paypal/create/${widget.userId}'),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          paymentUrl = 'http://10.0.2.2:8000/paypal/create/${widget.userId}';
        });

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebViewScreen(
              url: paymentUrl!,
              htmlContent: response.body,
            ),
          ),
        );

        if (!mounted) return;

        if (result == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment successful!')),
          );
          _fetchCartProducts();
        } else if (result == 'cancel') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment cancelled')),
          );
        }
      } else if (response.statusCode == 302) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          setState(() {
            paymentUrl = redirectUrl;
          });

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebViewScreen(
                url: redirectUrl,
                htmlContent: response.body,
              ),
            ),
          );

          if (!mounted) return;

          if (result == 'success') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment successful!')),
            );
            _fetchCartProducts();
          } else if (result == 'cancel') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment cancelled')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchCartProducts,
              child: ListView(
                padding: const EdgeInsets.all(8.0),
                children: [
                  if (products.isEmpty)
                    const Center(child: Text('No hay productos aún'))
                  else
                    Column(
                      children: products.map((product) {
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          child: ListTile(
                            title: Text(product['name']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product['description']),
                                Text(
                                    'Cantidad: ${product['pivot']['quantity']}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () =>
                                      _removeProduct(product['id']),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () => _addProduct(product['id']),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _createPayment,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Pagar'),
                  ),
                  if (paymentUrl != null) ...[
                    const SizedBox(height: 16.0),
                    Text(
                      'Payment URL: $paymentUrl',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

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

  void _initWebView() async {
    // Para versiones recientes de webview_flutter ya no es necesario llamar a setAcceptCookie.
    // if (Platform.isAndroid) {
    //   await WebViewCookieManager().setAcceptCookie(true);
    // }

    late final PlatformWebViewControllerCreationParams params;

    if (Platform.isAndroid) {
      params = AndroidWebViewControllerCreationParams();
    } else if (Platform.isIOS) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      throw UnsupportedError('Plataforma no soportada');
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..enableZoom(true)
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
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
            controller.runJavaScript('''
              document.cookie = "cookiesEnabled=true; path=/";
              localStorage.setItem('cookiesEnabled', 'true');
            ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.contains('paypal.com')) {
              return NavigationDecision.navigate;
            }
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
          },
        ),
      )
      ..addJavaScriptChannel(
        'PayPalBridge',
        onMessageReceived: (JavaScriptMessage message) {
        },
      )
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
      );

    if (Platform.isAndroid) {
      final AndroidWebViewController androidController =
          controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }

    // Cargar el HTML especificando la URL base para que el documento tenga origen definido
    controller.loadHtmlString(
      widget.htmlContent,
      baseUrl: widget.url,
    );

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
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

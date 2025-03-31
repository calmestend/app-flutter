import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  // Obtener productos del carrito
  Future<List<dynamic>> getCartProducts(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cart/$userId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }

      throw Exception('Failed to load cart products: ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Añadir producto al carrito
  Future<bool> addToCart(int userId, int productId, {int quantity = 1}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart/add/$userId/$productId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'quantity': quantity}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Remover producto del carrito
  Future<bool> removeFromCart(int userId, int productId,
      {int quantity = 1}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart/remove/$userId/$productId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'quantity': quantity}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Crear pago con PayPal
  Future<Map<String, dynamic>> createPayment(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/paypal/create/$userId'),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'url': '$baseUrl/paypal/create/$userId',
          'htmlContent': response.body,
        };
      } else if (response.statusCode == 302) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          return {
            'success': true,
            'url': redirectUrl,
            'htmlContent': response.body,
          };
        }
      }

      throw Exception('Failed to create payment: ${response.statusCode}');
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Verificar estado del pago
  Future<bool> verifyPayment(int userId, String paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/paypal/verify/$userId/$paymentId'),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Cancelar pago
  Future<bool> cancelPayment(int userId, String paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/paypal/cancel/$userId/$paymentId'),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

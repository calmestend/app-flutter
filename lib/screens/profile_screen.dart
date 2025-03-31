import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Perfil'),
      ),
      body: FutureBuilder<List<Purchase>>(
        future: fetchPurchases(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar las compras'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No hay compras disponibles'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            padding: EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final purchase = snapshot.data![index];
              return PurchaseCard(purchase: purchase);
            },
          );
        },
      ),
    );
  }
}

class PurchaseCard extends StatelessWidget {
  final Purchase purchase;

  const PurchaseCard({Key? key, required this.purchase}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormatter =
        DateFormat('dd/MM/yyyy HH:mm'); // Creamos el formateador

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Compra #${purchase.id}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dateFormatter
                      .format(purchase.createdAt), // Usamos el formateador
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Productos:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            ...purchase.details
                .map((product) => ProductItem(product: product))
                .toList(),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Total: \$${purchase.total}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ProductItem extends StatelessWidget {
  final ProductDetail product;

  const ProductItem({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${product.quantity}x \$${product.price}',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            '\$${(double.parse(product.price) * product.quantity).toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class Purchase {
  final int id;
  final String total;
  final DateTime createdAt;
  final List<ProductDetail> details;

  Purchase({
    required this.id,
    required this.total,
    required this.createdAt,
    required this.details,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    List<dynamic> detailsJson = jsonDecode(json['details']);
    return Purchase(
      id: json['id'],
      total: json['total'],
      createdAt: DateTime.parse(json['created_at']),
      details:
          detailsJson.map((detail) => ProductDetail.fromJson(detail)).toList(),
    );
  }
}

class ProductDetail {
  final int id;
  final String name;
  final String price;
  final int quantity;

  ProductDetail({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      quantity: json['pivot']['quantity'],
    );
  }
}

Future<List<Purchase>> fetchPurchases() async {
  try {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/purchases/user/8'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return (data['data'] as List)
          .map((purchase) => Purchase.fromJson(purchase))
          .toList();
    } else {
      throw Exception('Error al cargar las compras');
    }
  } catch (e) {
    throw Exception('Error de conexión: $e');
  }
}

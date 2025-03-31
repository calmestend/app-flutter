import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/user_state.dart';

class ProductsScreen extends StatefulWidget {
  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List _products = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final url = Uri.parse("http://10.0.2.2:8000/products");
    try {
      final response = await http.get(url, headers: {
        "Accept": "application/json",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _products = data["products"];
          _loading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Error fetching products: ${response.body}";
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error fetching products: $e";
        _loading = false;
      });
    }
  }

  Future<void> _addToCart(int productId) async {
    final userState = Provider.of<UserState>(context, listen: false);
    final userId = userState.userId;

    final url = Uri.parse("http://10.0.2.2:8000/cart/add/8/$productId");
    try {
      final response = await http.post(
        url,
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product added to cart')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to add product to cart: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add product to cart: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child:
                      Text(_errorMessage!, style: TextStyle(color: Colors.red)))
              : ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return ListTile(
                      title: Text(product["name"]),
                      subtitle: Text(product["description"]),
                      trailing: ElevatedButton(
                        onPressed: () => _addToCart(product["id"]),
                        child: Text("Agregar al carrito"),
                      ),
                    );
                  },
                ),
    );
  }
}

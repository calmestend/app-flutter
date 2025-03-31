import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  void _register() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final url = Uri.parse("http://10.0.2.2:8000/register");
    final response = await http.post(
      url,
      headers: {
        "Accept": "application/json",
      },
      body: {
        "name": _nameController.text,
        "email": _emailController.text,
        "password": _passwordController.text,
        "password_confirmation": _passwordConfirmController.text,
      },
    );

    print("Response Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      print("User registered successfully: ${data["user"]}");
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      setState(() {
        _errorMessage = "Error en el registro: ${response.body}";
      });
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contrasena'),
                obscureText: true,
              ),
              TextField(
                controller: _passwordConfirmController,
                decoration:
                    const InputDecoration(labelText: 'Confirmar Contrasena'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

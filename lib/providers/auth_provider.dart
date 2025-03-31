import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'user_state.dart';

class AuthProvider extends ChangeNotifier {
  bool _authenticated = false;
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _authenticated;
  Map<String, dynamic>? get user => _user;

  final String _apiUrl = 'http://10.0.2.2:8000';

  Future<void> login(
      BuildContext context, String email, String password) async {
    final url = Uri.parse('$_apiUrl/login');
    final response = await http.post(url, body: {
      'email': email,
      'password': password,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _user = data['user'];
      _authenticated = true;

      final userState = Provider.of<UserState>(context, listen: false);
      await userState.saveUser(data['user']['id'], data['access_token']);
      notifyListeners();
    } else {
      _authenticated = false;
      notifyListeners();
      throw Exception('Credenciales inválidas o error en el servidor.');
    }
  }

  Future<void> register(BuildContext context, String name, String email,
      String password, String passwordConfirmation) async {
    final url = Uri.parse('$_apiUrl/register');
    final response = await http.post(url, body: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      _user = data['user'];
      _authenticated = true;

      final userState = Provider.of<UserState>(context, listen: false);
      await userState.saveUser(data['user']['id'], data['access_token']);
      notifyListeners();
    } else {
      _authenticated = false;
      notifyListeners();
      throw Exception('Error en el registro.');
    }
  }

  Future<void> logout(BuildContext context) async {
    _authenticated = false;
    _user = null;

    final userState = Provider.of<UserState>(context, listen: false);
    await userState.clearUser();
    notifyListeners();
  }

  Future<void> tryAutoLogin(BuildContext context) async {
    final userState = Provider.of<UserState>(context, listen: false);
    await userState.loadUser();
    if (userState.userId != null) {
      _authenticated = true;
      notifyListeners();
    }
  }
}

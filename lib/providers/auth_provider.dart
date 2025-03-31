import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _authenticated = false;
  String? _accessToken;
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _authenticated;
  String? get accessToken => _accessToken;
  Map<String, dynamic>? get user => _user;

  final String _apiUrl = 'http://localhost:8000/api';

  Future<void> login(String email, String password) async {
    final url = Uri.parse('$_apiUrl/login');
    final response = await http.post(url, body: {
      'email': email,
      'password': password,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['access_token'];
      _user = data['user'];
      _authenticated = true;

      await _secureStorage.write(key: 'access_token', value: _accessToken);
      await _secureStorage.write(key: 'token_type', value: data['token_type']);
      notifyListeners();
    } else {
      _authenticated = false;
      notifyListeners();
      throw Exception('Credenciales inválidas o error en el servidor.');
    }
  }

  Future<void> register(String name, String email, String password, String passwordConfirmation) async {
    final url = Uri.parse('$_apiUrl/register');
    final response = await http.post(url, body: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      _accessToken = data['access_token'];
      _user = data['user'];
      _authenticated = true;

      await _secureStorage.write(key: 'access_token', value: _accessToken);
      await _secureStorage.write(key: 'token_type', value: data['token_type']);
      notifyListeners();
    } else {
      _authenticated = false;
      notifyListeners();
      throw Exception('Error en el registro.');
    }
  }

  Future<void> logout() async {
    _authenticated = false;
    _accessToken = null;
    _user = null;
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'token_type');
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final storedToken = await _secureStorage.read(key: 'access_token');
    if (storedToken != null) {
      _accessToken = storedToken;
      _authenticated = true;
      notifyListeners();
    }
  }
}

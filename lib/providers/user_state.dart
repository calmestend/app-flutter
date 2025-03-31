import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserState extends ChangeNotifier {
  int? _userId;
  String? _accessToken;

  int? get userId => _userId;
  String? get accessToken => _accessToken;

  Future<void> loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id');
    _accessToken = prefs.getString('access_token');
    notifyListeners();
  }

  Future<void> saveUser(int userId, String accessToken) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
    await prefs.setString('access_token', accessToken);
    _userId = userId;
    _accessToken = accessToken;
    notifyListeners();
  }

  Future<void> clearUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('access_token');
    _userId = null;
    _accessToken = null;
    notifyListeners();
  }
}

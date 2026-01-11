import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';
import '../utils/api_constants.dart';

class AuthService extends ChangeNotifier {
  final SharedPreferences _prefs;
  String? _token;
  User? _user;

  AuthService(this._prefs) {
    _loadToken();
  }

  bool get isAuthenticated => _token != null;
  String? get token => _token;
  User? get user => _user;

  Future<void> _loadToken() async {
    _token = _prefs.getString('auth_token');
    if (_token != null) {
      final userJson = _prefs.getString('user');
      if (userJson != null) {
        _user = User.fromJson(jsonDecode(userJson));
      }
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _user = User.fromJson(data['user']);
        
        await _prefs.setString('auth_token', _token!);
        await _prefs.setString('user', jsonEncode(_user!.toJson()));
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _user = User.fromJson(data['user']);
        
        await _prefs.setString('auth_token', _token!);
        await _prefs.setString('user', jsonEncode(_user!.toJson()));
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await _prefs.remove('auth_token');
    await _prefs.remove('user');
    notifyListeners();
  }

  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // Web uyumluluğu için: getCurrentUser
  Future<User?> getCurrentUser() async {
    if (_token == null) return null;
    
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.userProfile}'),
        headers: getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = User.fromJson(data);
        await _prefs.setString('user', jsonEncode(_user!.toJson()));
        notifyListeners();
        return _user;
      }
      return null;
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  // Web uyumluluğu için: updateProfile
  Future<bool> updateProfile({String? name, String? email}) async {
    if (_token == null) return false;
    
    try {
      final body = <String, dynamic>{};
      if (name != null) body['userName'] = name;
      if (email != null) body['email'] = email;
      
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.userProfile}'),
        headers: getAuthHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = User.fromJson(data);
        await _prefs.setString('user', jsonEncode(_user!.toJson()));
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Update profile error: $e');
      return false;
    }
  }
}

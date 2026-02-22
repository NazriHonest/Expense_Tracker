import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final _apiService = ApiService();

  String? _token;
  bool _isLoading = false;
  bool _isInitializing = true;

  // Getters
  bool get isAuth => _token != null && !JwtDecoder.isExpired(_token!);
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get token => _token;

  /// Decodes the email directly from the JWT.
  /// Since you updated the backend, this will work automatically.
  String? get userEmail {
    if (_token == null) return null;
    try {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(_token!);
      return decodedToken['email'] ?? "User";
    } catch (e) {
      return "User";
    }
  }

  /// Automatically called on app startup
  Future<void> tryAutoLogin() async {
    _isInitializing = true;
    notifyListeners();

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token != null && !JwtDecoder.isExpired(token)) {
        _token = token;
      }
    } finally {
      _isInitializing = false; // Done checking, stop showing splash
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await _apiService.login(email, password);
      _token = token;

      // Persist token for auto-login
      await _storage.write(key: 'jwt_token', value: token);

      notifyListeners();
    } catch (e) {
      rethrow; // Pass error to UI for SnackBar display
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.register(email, password);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    await _storage.delete(key: 'jwt_token');
    // Once _token is null, the ApiService interceptor will stop sending auth headers
    notifyListeners();
  }
}

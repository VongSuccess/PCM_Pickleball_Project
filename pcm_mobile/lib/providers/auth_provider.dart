import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/signalr_service.dart';
import '../services/cache_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;
  ApiService get apiService => _apiService;

  final SignalRService _signalRService = SignalRService();

  SignalRService get signalRService => _signalRService;

  Future<void> init() async {
    await _apiService.loadToken();
    if (!_apiService.hasToken) {
      // Try load offline profile if token exists but network might fail later?
      // Actually we need token to be considered "logged in" usually.
      // But if we want offline mode, we might trust the cached token? 
      // For now, let's just proceed.
      return;
    }
    try {
      final response = await _apiService.getCurrentUser();
      if (response.data['success'] == true && response.data['user'] != null) {
        _user = UserModel.fromJson(response.data['user']);
        
        // Cache user profile
        await CacheService.cacheUserProfile(response.data['user']);

        // Init SignalR
        final token = await _apiService.getToken();
        final signalRUrl = ApiService.baseUrl.replaceAll('/api', '');
        await _signalRService.init(signalRUrl, token: token);
        notifyListeners();
      }
    } catch (e) {
      // Try load from cache
      final cachedProfile = CacheService.getCachedUserProfile();
      if (cachedProfile != null) {
        _user = UserModel.fromJson(cachedProfile);
        print('Loaded user profile from cache');
        notifyListeners();
      } else {
        await _apiService.clearToken();
      }
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.login(username, password);
      final authResponse = AuthResponse.fromJson(response.data);
      
      if (authResponse.success && authResponse.token != null) {
        await _apiService.saveToken(authResponse.token!);
        _user = authResponse.user;
        
        // Init SignalR
        final signalRUrl = ApiService.baseUrl.replaceAll('/api', '');
        await _signalRService.init(signalRUrl, token: authResponse.token);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = authResponse.message ?? 'Đăng nhập thất bại';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionError) {
          _error = 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra internet hoặc Firewall.';
        } else {
          _error = 'Lỗi hệ thống: ${e.message}';
        }
      } else {
        _error = 'Lỗi kết nối: $e';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String email, String password, String fullName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.register(username, email, password, fullName);
      final authResponse = AuthResponse.fromJson(response.data);
      
      if (authResponse.success && authResponse.token != null) {
        await _apiService.saveToken(authResponse.token!);
        _user = authResponse.user;

        // Init SignalR - Sử dụng URL động từ ApiService
        final signalRUrl = ApiService.baseUrl.replaceAll('/api', '');
        await _signalRService.init(signalRUrl, token: authResponse.token);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = authResponse.message ?? 'Đăng ký thất bại';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionError) {
          _error = 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra internet hoặc Firewall.';
        } else {
          _error = 'Lỗi hệ thống: ${e.message}';
        }
      } else {
        _error = 'Lỗi kết nối: $e';
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _signalRService.stop();
    await _apiService.clearToken();
    await CacheService.clear();
    _user = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    try {
      final response = await _apiService.getCurrentUser();
      if (response.data['success'] == true && response.data['user'] != null) {
        _user = UserModel.fromJson(response.data['user']);
        notifyListeners();
      }
    } catch (e) {
      // Ignore errors
    }
  }
}

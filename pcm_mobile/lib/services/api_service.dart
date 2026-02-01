import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // Production URL - Render.com
  static String get baseUrl {
    // Luôn sử dụng URL production trên Render
    return 'https://pcm-pickleball-project.onrender.com/api';
  }
  
  late Dio _dio;
  String? _token;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        String errorMessage = 'Lỗi không xác định';
        
        if (error.type == DioExceptionType.connectionError) {
          errorMessage = 'Không thể kết nối đến máy chủ. ';
          if (kIsWeb) {
            errorMessage += 'Vui lòng kiểm tra CORS hoặc Mixed Content (HTTPS vs HTTP).';
          } else {
            errorMessage += 'Vui lòng kiểm tra kết nối internet hoặc Firewall.';
          }
        } else if (error.type == DioExceptionType.connectionTimeout) {
          errorMessage = 'Kết nối quá hạn (Timeout).';
        } else if (error.response?.statusCode == 401) {
          errorMessage = 'Phiên đăng nhập hết hạn hoặc sai thông tin.';
        } else if (error.response?.statusCode == 400 || error.response?.statusCode == 404 || error.response?.statusCode == 500) {
          // Trích xuất thông báo lỗi từ Backend
          if (error.response?.data != null) {
            final data = error.response?.data;
            if (data is String) {
              errorMessage = data;
            } else if (data is Map<String, dynamic>) {
              if (data.containsKey('message')) {
                errorMessage = data['message'];
              } else if (data.containsKey('title')) {
                errorMessage = data['title'];
              } else {
                errorMessage = data.toString();
              }
            }
          }
        }
        
        print('API Error [${error.requestOptions.path}]: $errorMessage');
        // Truyền message lỗi tùy chỉnh qua error object để UI hiển thị
        return handler.next(DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          type: error.type,
          error: errorMessage, 
          message: errorMessage,
        ));
      },
    ));
  }

  void setToken(String token) {
    _token = token;
  }

  bool get hasToken => _token != null && _token!.isNotEmpty;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    _token = token;
  }

  Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    return _token;
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _token = null;
  }

  // ============ AUTH ============
  Future<Response> login(String username, String password) async {
    return await _dio.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
  }

  Future<Response> register(String username, String email, String password, String fullName) async {
    return await _dio.post('/auth/register', data: {
      'username': username,
      'email': email,
      'password': password,
      'fullName': fullName,
    });
  }

  Future<Response> getCurrentUser() async {
    return await _dio.get('/auth/me');
  }

  // ============ WALLET ============
  Future<Response> getWalletInfo() async {
    return await _dio.get('/wallet');
  }

  Future<Response> getTransactions({int page = 1, int pageSize = 20}) async {
    return await _dio.get('/wallet/transactions', queryParameters: {
      'page': page,
      'pageSize': pageSize,
    });
  }

  Future<Response> requestDeposit(double amount, String? description, String? imagePath) async {
    final formData = FormData.fromMap({
      'amount': amount,
      'description': description,
    });

    if (imagePath != null && imagePath.isNotEmpty) {
      formData.files.add(MapEntry(
        'proofImage',
        await MultipartFile.fromFile(imagePath),
      ));
    }

    return await _dio.post('/wallet/deposit', data: formData);
  }

  // ============ COURTS ============
  Future<Response> getCourts() async {
    return await _dio.get('/courts');
  }

  Future<Response> getCourt(int id) async {
    return await _dio.get('/courts/$id');
  }

  Future<Response> createCourt(Map<String, dynamic> data) async {
    return await _dio.post('/courts', data: data);
  }

  Future<Response> updateCourt(int id, Map<String, dynamic> data) async {
    return await _dio.put('/courts/$id', data: data);
  }

  Future<Response> deleteCourt(int id) async {
    return await _dio.delete('/courts/$id');
  }

  // ============ BOOKINGS ============
  Future<Response> getCalendar(DateTime from, DateTime to) async {
    return await _dio.get('/bookings/calendar', queryParameters: {
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
    });
  }

  Future<Response> getMyBookings() async {
    return await _dio.get('/bookings/my');
  }

  Future<Response> createBooking(int courtId, DateTime startTime, DateTime endTime) async {
    return await _dio.post('/bookings', data: {
      'courtId': courtId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    });
  }

  Future<Response> createRecurringBooking({
    required int courtId,
    required String recurrenceRule,
    required DateTime startDate,
    required DateTime endDate,
    required String startTime,
    required String endTime,
  }) async {
    return await _dio.post('/bookings/recurring', data: {
      'courtId': courtId,
      'recurrenceRule': recurrenceRule,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
    });
  }

  Future<Response> cancelBooking(int bookingId) async {
    return await _dio.post('/bookings/cancel/$bookingId');
  }

  // ============ TOURNAMENTS ============
  Future<Response> getTournaments({String? status}) async {
    return await _dio.get('/tournaments', queryParameters: 
      status != null ? {'status': status} : null);
  }

  Future<Response> getTournament(int id) async {
    return await _dio.get('/tournaments/$id');
  }

  Future<Response> joinTournament(int tournamentId, String teamName) async {
    return await _dio.post('/tournaments/$tournamentId/join', data: {
      'teamName': teamName,
    });
  }

  Future<Response> createTournament(Map<String, dynamic> data) async {
    return await _dio.post('/tournaments', data: data);
  }

  Future<Response> finishTournament(int id) async {
    return await _dio.post('/tournaments/$id/finish');
  }

  Future<Response> updateMatchResult(int id, int score1, int score2, String? details) async {
    return await _dio.post('/matches/$id/result', data: {
      'score1': score1,
      'score2': score2,
      'details': details
    });
  }

  // ============ NOTIFICATIONS ============
  Future<Response> getNotifications({bool unreadOnly = false}) async {
    return await _dio.get('/notifications', queryParameters: {
      'unreadOnly': unreadOnly,
    });
  }

  Future<Response> getUnreadCount() async {
    return await _dio.get('/notifications/count');
  }

  Future<Response> updateFcmToken(String token) async {
    return await _dio.put('/notifications/fcm-token', data: {
      'token': token,
    });
  }

  Future<Response> markNotificationRead(int id) async {
    return await _dio.put('/notifications/$id/read');
  }

  Future<Response> markAllNotificationsRead() async {
    return await _dio.put('/notifications/read-all');
  }

  // ============ MEMBERS ============
  Future<Response> getMembers({String? search, String? tier, int page = 1}) async {
    final params = <String, dynamic>{'page': page};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (tier != null) params['tier'] = tier;
    return await _dio.get('/members', queryParameters: params);
  }

  Future<Response> getMemberProfile(String id) async {
    return await _dio.get('/members/$id/profile');
  }

  Future<Response> updateMember(String id, Map<String, dynamic> data) async {
    return await _dio.put('/members/$id', data: data);
  }

  // ============ MATCHES ============
  Future<Response> getMatches({int? tournamentId, String? status}) async {
    final params = <String, dynamic>{};
    if (tournamentId != null) params['tournamentId'] = tournamentId;
    if (status != null) params['status'] = status;
    return await _dio.get('/matches', queryParameters: params.isEmpty ? null : params);
  }

  Future<Response> getMatch(int id) async {
    return await _dio.get('/matches/$id');
  }

  Future<Response> getMyMatches() async {
    return await _dio.get('/matches/my');
  }

  Future<Response> createDuel(String opponentId) async {
    return await _dio.post('/matches/duel', data: {
      'opponentId': opponentId,
    });
  }

  // ============ ADMIN ============
  Future<Response> generateSchedule(int tournamentId) async {
    return await _dio.post('/tournaments/$tournamentId/generate-schedule');
  }

  Future<Response> getAdminDashboard() async {
    return await _dio.get('/admin/dashboard');
  }

  Future<Response> getPendingDeposits() async {
    return await _dio.get('/admin/wallet/pending');
  }

  Future<Response> approveDeposit(int transactionId) async {
    return await _dio.put('/admin/wallet/approve/$transactionId');
  }

  Future<Response> rejectDeposit(int transactionId, String reason) async {
    return await _dio.put('/admin/wallet/reject/$transactionId', data: {
      'reason': reason,
    });
  }

  // ============ PAYMENT ============
  Future<Response> createPaymentUrl(double amount, String orderDescription) async {
    return await _dio.post('/payment/vnpay/create-url', data: {
      'amount': amount,
      'orderDescription': orderDescription,
      'name': 'User Deposit', // Optional
      'orderType': 'deposit'
    });
  }
}


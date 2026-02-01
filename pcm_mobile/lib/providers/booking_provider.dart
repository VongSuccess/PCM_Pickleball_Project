import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/booking_model.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class BookingProvider with ChangeNotifier {
  final ApiService _apiService;
  List<CourtModel> _courts = [];
  List<BookingModel> _calendarBookings = [];
  List<BookingModel> _myBookings = [];
  bool _isLoading = false;
  String? _error;

  BookingProvider(this._apiService);

  List<CourtModel> get courts => _courts;
  List<BookingModel> get calendarBookings => _calendarBookings;
  List<BookingModel> get myBookings => _myBookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCourts() async {
    try {
      final response = await _apiService.getCourts();
      final List<dynamic> data = response.data;
      _courts = data.map((e) => CourtModel.fromJson(e)).toList();
      
      // Cache data
      await CacheService.cacheCourts(data);
      
      notifyListeners();
    } catch (e) {
      // Try to load from cache
      final cachedData = CacheService.getCachedCourts();
      if (cachedData != null) {
        _courts = cachedData.map((e) => CourtModel.fromJson(e)).toList();
        print('Loaded ${cachedData.length} courts from cache');
      } else {
        _error = e.toString();
      }
      notifyListeners();
    }
  }

  Future<void> loadCalendar(DateTime from, DateTime to) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getCalendar(from, to);
      final List<dynamic> data = response.data;
      _calendarBookings = data.map((e) => BookingModel.fromJson(e)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadMyBookings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getMyBookings();
      final List<dynamic> data = response.data;
      _myBookings = data.map((e) => BookingModel.fromJson(e)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = extractError(e); // Added error handling here
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createBooking(int courtId, DateTime startTime, DateTime endTime) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('🔄 Creating booking: courtId=$courtId, startTime=$startTime, endTime=$endTime');
      final response = await _apiService.createBooking(courtId, startTime, endTime);
      print('✅ Booking response: ${response.data}');

      _isLoading = false;
      notifyListeners();
      return {'success': true, 'message': response.data['Message'] ?? 'Đặt sân thành công'};
    } catch (e) {
      print('❌ Booking error: $e');
      _isLoading = false;
      _error = extractError(e);
      print('❌ Extracted error: $_error');
      notifyListeners();
      return {'success': false, 'message': _error};
    }
  }

  Future<Map<String, dynamic>> createRecurringBooking({
    required int courtId,
    required String recurrenceRule,
    required DateTime startDate,
    required DateTime endDate,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.createRecurringBooking(
        courtId: courtId,
        recurrenceRule: recurrenceRule,
        startDate: startDate,
        endDate: endDate,
        startTime: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
        endTime: '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00',
      );

      _isLoading = false;
      notifyListeners();
      return {'success': true, 'message': response.data['Message']};
    } catch (e) {
      _isLoading = false;
      _error = extractError(e);
      notifyListeners();
      return {'success': false, 'message': _error};
    }
  }

  Future<Map<String, dynamic>> cancelBooking(int bookingId) async {
    try {
      final response = await _apiService.cancelBooking(bookingId);
      await loadMyBookings();
      return {'success': true, 'message': response.data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Hủy booking thất bại'};
    }
  }

  String extractError(dynamic e) {
    if (e is DioException) {
      return e.response?.data?.toString() ?? e.message ?? 'Lỗi kết nối';
    }
    return e.toString();
  }
}

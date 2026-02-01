import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class WalletProvider with ChangeNotifier {
  final ApiService _apiService;
  WalletInfo? _walletInfo;
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;

  String? _error;

  WalletProvider(this._apiService);

  WalletInfo? get walletInfo => _walletInfo;
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  double get balance => _walletInfo?.balance ?? 0;
  String? get error => _error;

  Future<void> loadWalletInfo() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getWalletInfo();
      _walletInfo = WalletInfo.fromJson(response.data);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadTransactions({int page = 1}) async {
    try {
      final response = await _apiService.getTransactions(page: page);
      final List<dynamic> data = response.data;
      if (page == 1) {
        _transactions = data.map((e) => TransactionModel.fromJson(e)).toList();
      } else {
        _transactions.addAll(data.map((e) => TransactionModel.fromJson(e)));
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> requestDeposit(double amount, String description, String? imagePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _apiService.requestDeposit(amount, description, imagePath);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> initiateVnPayDeposit(double amount, String description) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiService.createPaymentUrl(amount, description);
      _isLoading = false;
      notifyListeners();
      return response.data['url'];
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}

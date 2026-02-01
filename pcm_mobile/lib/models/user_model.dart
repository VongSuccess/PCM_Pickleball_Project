class UserModel {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final double walletBalance;
  final String tier;
  final String? avatarUrl;
  final double? duprRank;
  final String role;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.walletBalance,
    required this.tier,
    this.avatarUrl,
    this.duprRank,
    this.role = 'Member', 
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      walletBalance: (json['walletBalance'] ?? 0).toDouble(),
      tier: json['tier'] ?? 'Standard',
      avatarUrl: json['avatarUrl'],
      duprRank: json['duprRank'] != null ? (json['duprRank'] as num).toDouble() : null,
      role: json['role'] ?? 'Member',
    );
  }
}

class AuthResponse {
  final bool success;
  final String? message;
  final String? token;
  final UserModel? user;

  AuthResponse({
    required this.success,
    this.message,
    this.token,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'],
      token: json['token'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}

class TransactionModel {
  final int id;
  final double amount;
  final String type;
  final String status;
  final String? description;
  final DateTime createdDate;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.status,
    this.description,
    required this.createdDate,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      description: json['description'],
      createdDate: DateTime.parse(json['createdDate']),
    );
  }
}

class WalletInfo {
  final double balance;
  final List<TransactionModel> recentTransactions;

  WalletInfo({
    required this.balance,
    required this.recentTransactions,
  });

  factory WalletInfo.fromJson(Map<String, dynamic> json) {
    return WalletInfo(
      balance: (json['balance'] ?? 0).toDouble(),
      recentTransactions: (json['recentTransactions'] as List? ?? [])
          .map((e) => TransactionModel.fromJson(e))
          .toList(),
    );
  }
}

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class BiometricService {
  final LocalAuthentication auth = LocalAuthentication();
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  
  static const String _keyUsername = 'biometric_username';
  static const String _keyPassword = 'biometric_password'; // In real app, store token or hash
  
  /// Kiểm tra thiết bị có hỗ trợ Biometric không
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Error checking biometrics: $e');
      return false;
    }
  }

  /// Thực hiện xác thực vân tay/FaceID
  Future<bool> authenticate() async {
    try {
      return await auth.authenticate(
        localizedReason: 'Vui lòng xác thực để đăng nhập',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('Error authenticating: $e');
      return false;
    }
  }

  /// Lưu credentials an toàn
  Future<void> saveCredentials(String username, String password) async {
    await storage.write(key: _keyUsername, value: username);
    await storage.write(key: _keyPassword, value: password);
  }

  /// Lấy credentials (nếu có)
  Future<Map<String, String>?> getCredentials() async {
    final username = await storage.read(key: _keyUsername);
    final password = await storage.read(key: _keyPassword);
    
    if (username != null && password != null) {
      return {
        'username': username,
        'password': password,
      };
    }
    return null;
  }

  /// Xóa credentials
  Future<void> clearCredentials() async {
    await storage.delete(key: _keyUsername);
    await storage.delete(key: _keyPassword);
  }
}

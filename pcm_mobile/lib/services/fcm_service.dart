import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class FCMService {
  final ApiService _apiService = ApiService();

  Future<void> init() async {
    try {
      // Initialize Firebase
      // Important: Ensure valid google-services.json is present in android/app
      await Firebase.initializeApp();
      
      final messaging = FirebaseMessaging.instance;
      
      // Request permission
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission: ${settings.authorizationStatus}');
        
        // Get Token
        final token = await messaging.getToken();
        if (token != null) {
          debugPrint('FCM Token: $token');
          await _sendTokenToBackend(token);
        }

        // Listen for token refresh
        messaging.onTokenRefresh.listen((newToken) {
          _sendTokenToBackend(newToken);
        });

        // Handle Foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('Got a message whilst in the foreground!');
          debugPrint('Message data: ${message.data}');

          if (message.notification != null) {
            debugPrint('Message also contained a notification: ${message.notification}');
            // TODO: Show local notification or update UI
          }
        });
      } else {
        debugPrint('User declined or has not accepted permission');
      }
    } catch (e) {
      debugPrint('FCM Init Warning: $e'); 
      debugPrint('If you are seeing this, you probably need to add google-services.json to android/app');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      // Ensure we have token
      await _apiService.loadToken();
      
      // Only send if we have a token (logged in)
      if (_apiService.hasToken) {
        await _apiService.updateFcmToken(token);
        debugPrint('Sent FCM token to backend');
      }
    } catch (e) {
      debugPrint('Error sending FCM token: $e');
    }
  }
}

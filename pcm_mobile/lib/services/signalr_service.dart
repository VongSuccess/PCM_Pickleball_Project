import 'package:signalr_core/signalr_core.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';


class SignalRService {
  HubConnection? _hubConnection;
  // final String _hubUrl = 'http://10.0.2.2:5294/pcmhub'; // Default for Android Emulator

  // Streams
  final _notificationController = StreamController<dynamic>.broadcast();
  final _calendarController = StreamController<dynamic>.broadcast();
  final _matchController = StreamController<dynamic>.broadcast();

  Stream<dynamic> get notificationStream => _notificationController.stream;
  Stream<dynamic> get calendarUpdateStream => _calendarController.stream;
  Stream<dynamic> get matchUpdateStream => _matchController.stream;

  bool get isConnected => _hubConnection?.state == HubConnectionState.connected;

  Future<void> init(String baseUrl, {String? token}) async {
    final hubUrl = '$baseUrl/pcmhub';
    
    _hubConnection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          HttpConnectionOptions(
            accessTokenFactory: () async => token ?? '',
            logging: (level, message) => debugPrint('SignalR: $message'),
            skipNegotiation: true,
            transport: HttpTransportType.webSockets,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _hubConnection?.onclose((error) {
      debugPrint('SignalR Connection Closed: $error');
    });

    _registerHandlers();

    try {
      await _hubConnection?.start();
      debugPrint('SignalR Connected to $hubUrl');
    } catch (e) {
      debugPrint('SignalR Connection Error: $e');
    }
  }

  void _registerHandlers() {
    if (_hubConnection == null) return;

    _hubConnection!.on('ReceiveNotification', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        debugPrint('SignalR ReceiveNotification: ${arguments[0]}');
        _notificationController.add(arguments[0]);
      }
    });

    _hubConnection!.on('UpdateCalendar', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        debugPrint('SignalR UpdateCalendar: ${arguments[0]}');
        _calendarController.add(arguments[0]);
      }
    });

    _hubConnection!.on('UpdateMatchScore', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        debugPrint('SignalR UpdateMatchScore: ${arguments[0]}');
        _matchController.add(arguments[0]);
      }
    });
  }

  Future<void> stop() async {
    if (_hubConnection != null) {
      await _hubConnection!.stop();
    }
    await _notificationController.close();
    await _calendarController.close();
    await _matchController.close();
  }

  Future<void> joinMatchGroup(int matchId) async {
    if (isConnected) {
      await _hubConnection!.invoke('JoinMatchGroup', args: [matchId]);
    }
  }

  Future<void> leaveMatchGroup(int matchId) async {
    if (isConnected) {
      await _hubConnection!.invoke('LeaveMatchGroup', args: [matchId]);
    }
  }
}

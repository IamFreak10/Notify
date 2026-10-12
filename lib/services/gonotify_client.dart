import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/notification_model.dart';

enum ConnectionStatus { disconnected, connecting, connected }

class GonotifyClient {
  String serverUrl;
  final List<String> topics;
  final void Function(NotificationModel notification) onMessageReceived;
  final void Function(ConnectionStatus status) onStatusChanged;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _shouldReconnect = true;
  Timer? _reconnectTimer;
  ConnectionStatus _status = ConnectionStatus.disconnected;

  GonotifyClient({
    required this.serverUrl,
    required this.topics,
    required this.onMessageReceived,
    required this.onStatusChanged,
  });

  ConnectionStatus get status => _status;

  void _setStatus(ConnectionStatus s) {
    if (_status != s) {
      _status = s;
      onStatusChanged(s);
    }
  }

  void connect() {
    _shouldReconnect = true;
    _reconnectTimer?.cancel();
    _setStatus(ConnectionStatus.connecting);

    try {
      final uri = Uri.parse(serverUrl).replace(queryParameters: {
        'topic': topics,
      });

      debugPrint('[NotifyApp] Connecting to $uri...');
      _channel = WebSocketChannel.connect(uri);

      // Immediately transition status to Connected once WebSocket handshake completes
      _channel!.ready.then((_) {
        _setStatus(ConnectionStatus.connected);
      }).catchError((err) {
        debugPrint('[NotifyApp] Handshake error: $err');
      });

      _subscription = _channel!.stream.listen(
        (data) {
          _setStatus(ConnectionStatus.connected);
          try {
            final jsonMap = jsonDecode(data as String) as Map<String, dynamic>;
            if (jsonMap['event'] == 'pong') return;

            final notification = NotificationModel.fromJson(jsonMap);
            onMessageReceived(notification);
          } catch (e) {
            debugPrint('[NotifyApp] Parse error: $e');
          }
        },
        onError: (err) {
          debugPrint('[NotifyApp] WebSocket error: $err');
          _setStatus(ConnectionStatus.disconnected);
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('[NotifyApp] WebSocket closed.');
          _setStatus(ConnectionStatus.disconnected);
          _scheduleReconnect();
        },
      );
    } catch (e) {
      debugPrint('[NotifyApp] Connection setup error: $e');
      _setStatus(ConnectionStatus.disconnected);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 4), () {
      debugPrint('[NotifyApp] Auto-reconnecting...');
      connect();
    });
  }

  void updateServerUrl(String newUrl) {
    serverUrl = newUrl;
    disconnect();
    connect();
  }

  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _setStatus(ConnectionStatus.disconnected);
  }
}

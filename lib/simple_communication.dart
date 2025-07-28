import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/widgets.dart';

/// Main bridge class for cross-app communication (Native-Flutter Web and Flutter Web-Flutter Web)
class SimpleCommunication {
  static final SimpleCommunication _instance = SimpleCommunication._internal();
  factory SimpleCommunication() => _instance;
  SimpleCommunication._internal();

  // Static getter for easy access without context
  static SimpleCommunication get instance => _instance;

  // Configurable logging - can be set at runtime
  static bool _logEnabled = false;
  static bool get logEnabled => _logEnabled;
  static set logEnabled(bool value) => _logEnabled = value;

  final _messageController = StreamController<CommunicationMessage>.broadcast();
  Timer? _pollTimer;
  String? _appId;
  CommunicationType _communicationType = CommunicationType.auto;
  Timer? _heartbeatTimer;
  String _urlScheme = 'simplecommunication'; // Default URL scheme

  // Web communication
  html.BroadcastChannel? _channel;
  bool _useBroadcastChannel = false;

  // Configuration - Fixed: Use consistent keys
  static const String _messageQueuePrefix = 'msg_';
  static const String _messageCounter = 'msg_counter';
  static const String _ackPrefix = 'ack_';
  static const Duration _pollInterval = Duration(milliseconds: 100);
  static const Duration _ackTimeout = Duration(seconds: 5);

  /// Initialize the communication bridge with an app identifier
  /// [appId] - Unique identifier for this app instance
  /// [communicationType] - Type of communication to use (auto, native, web)
  /// [enableLogging] - Enable console logging (default: false for production)
  /// [urlScheme] - Custom URL scheme for native communication (default: 'simplecommunication')
  void initialize({
    required String appId,
    CommunicationType communicationType = CommunicationType.auto,
    bool enableLogging = false,
    String urlScheme = 'simplecommunication',
  }) {
    _logEnabled = enableLogging;
    _urlScheme = urlScheme;
    if (_logEnabled) {
      print(
          '[SimpleCommunication] Initializing with appId: $appId, type: $communicationType, urlScheme: $_urlScheme');
    }
    _appId = appId;
    _communicationType = communicationType;
    _initializeWebCommunication();
    _startListening();

    // Check for initial data in URL
    _checkUrlParams();
    if (_logEnabled) {
      print('[SimpleCommunication] Initialization complete');
    }
  }

  /// Initialize web communication with BroadcastChannel fallback to localStorage
  void _initializeWebCommunication() {
    try {
      _channel = html.BroadcastChannel('simple_communication');
      _channel!.onMessage.listen(_handleBroadcastMessage);
      _useBroadcastChannel = true;
      if (_logEnabled) {
        print(
            '[SimpleCommunication] BroadcastChannel initialized successfully');
      }
    } catch (e) {
      _useBroadcastChannel = false;
      if (_logEnabled) {
        print(
            '[SimpleCommunication] BroadcastChannel not supported, using localStorage fallback');
      }
    }
  }

  /// Handle messages from BroadcastChannel
  void _handleBroadcastMessage(html.MessageEvent event) {
    try {
      final data = event.data as Map<String, dynamic>;
      final message = CommunicationMessage.fromJson(data);

      // Check if message is for this app or broadcast
      if (message.target == null || message.target == _appId) {
        if (_logEnabled) {
          print(
              '[SimpleCommunication] Received broadcast message: ${message.action}');
        }

        // Send acknowledgment
        _sendAcknowledgment(message.id);

        // Emit message
        _messageController.add(message);
      }
    } catch (e) {
      if (_logEnabled) {
        print('[SimpleCommunication] Error handling broadcast message: $e');
      }
    }
  }

  /// Stream of incoming messages from other apps
  Stream<CommunicationMessage> get messages => _messageController.stream;

  /// Send data to another app (native or web)
  Future<bool> sendMessage(
    String action,
    Map<String, dynamic> data, {
    String? targetAppId,
  }) async {
    if (_logEnabled) {
      print(
          '[SimpleCommunication] Sending message - Action: $action, Data: $data, Target: $targetAppId');
    }

    final messageId = _generateMessageId();
    final message = <String, dynamic>{
      'id': messageId,
      'action': action,
      'data': data,
      'source': _appId,
      'target': targetAppId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    if (_logEnabled) {
      print('[SimpleCommunication] Generated message: $message');
    }

    bool success = false;

    // Determine communication method based on type and target
    if (_communicationType == CommunicationType.native ||
        (_communicationType == CommunicationType.auto && targetAppId == null)) {
      // Try native communication first
      if (_logEnabled) {
        print('[SimpleCommunication] Attempting native communication...');
      }
      success = await _sendViaNative(message);
    }

    if (!success &&
        (_communicationType == CommunicationType.web ||
            _communicationType == CommunicationType.auto)) {
      // Use web communication (BroadcastChannel or localStorage)
      if (_logEnabled) {
        print('[SimpleCommunication] Using web communication');
      }
      success = await _sendViaWeb(message);
    }

    if (success) {
      if (_logEnabled) {
        print('[SimpleCommunication] Message sent successfully');
      }
      // Wait for acknowledgment
      final ackResult = await _waitForAcknowledgment(messageId);
      if (_logEnabled) {
        print('[SimpleCommunication] Acknowledgment result: $ackResult');
      }
      return ackResult;
    }

    if (_logEnabled) {
      print('[SimpleCommunication] Failed to send message');
    }
    return false;
  }

  /// Navigate to another Flutter app
  void navigateToApp(String appPath, Map<String, dynamic> params) {
    if (_logEnabled) {
      print(
          '[SimpleCommunication] Navigating to app: $appPath with params: $params');
    }

    final updatedParams = <String, dynamic>{...params, 'from_app': _appId};
    final queryString = Uri(
      queryParameters: updatedParams.map((k, v) => MapEntry(k, v.toString())),
    ).query;

    final targetUrl = '${html.window.location.origin}/$appPath?$queryString';
    if (_logEnabled) {
      print('[SimpleCommunication] Target URL: $targetUrl');
    }

    sendMessage('navigate', {'url': targetUrl, 'params': updatedParams});
  }

  /// Store session data accessible to all apps on the same domain
  void setSessionData(String key, dynamic value) {
    if (_logEnabled) {
      print(
          '[SimpleCommunication] Setting session data - Key: $key, Value: $value');
    }

    final sessionKey = 'session_$key';
    html.window.localStorage[sessionKey] = jsonEncode(value);

    if (_logEnabled) {
      print(
          '[SimpleCommunication] Session data stored in localStorage with key: $sessionKey');
    }

    // Notify other apps about session update
    sendMessage('sessionUpdate', {
      'key': key,
      'value': value,
    });
  }

  /// Retrieve session data
  T? getSessionData<T>(String key) {
    if (_logEnabled) {
      print('[SimpleCommunication] Getting session data for key: $key');
    }

    final sessionKey = 'session_$key';
    final data = html.window.localStorage[sessionKey];
    if (data != null) {
      try {
        final decoded = jsonDecode(data) as T;
        if (_logEnabled) {
          print('[SimpleCommunication] Retrieved session data: $decoded');
        }
        return decoded;
      } catch (e) {
        if (_logEnabled) {
          print('[SimpleCommunication] Error decoding session data: $e');
        }
        return null;
      }
    }
    if (_logEnabled) {
      print('[SimpleCommunication] No session data found for key: $key');
    }
    return null;
  }

  /// Clear all session data
  void clearSession() {
    if (_logEnabled) {
      print('[SimpleCommunication] Clearing all session data');
    }

    final keys = html.window.localStorage.keys
        .where((k) => k.startsWith('session_'))
        .toList();

    if (_logEnabled) {
      print(
          '[SimpleCommunication] Found ${keys.length} session keys to clear: $keys');
    }

    for (final key in keys) {
      html.window.localStorage.remove(key);
      if (_logEnabled) {
        print('[SimpleCommunication] Removed session key: $key');
      }
    }
    sendMessage('sessionCleared', {});
  }

  /// Get list of active apps on the same domain
  List<String> getActiveApps() {
    final apps = <String>[];
    final keys = html.window.localStorage.keys
        .where((k) => k.startsWith('app_heartbeat_'))
        .toList();

    for (final key in keys) {
      final appId = key.replaceFirst('app_heartbeat_', '');
      final timestamp = int.tryParse(html.window.localStorage[key] ?? '0') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Consider app active if heartbeat is less than 10 seconds old
      if (now - timestamp < 10000) {
        apps.add(appId);
      }
    }

    if (_logEnabled) {
      print('[SimpleCommunication] Active apps: $apps');
    }
    return apps;
  }

  // Private methods

  void _startListening() {
    if (_logEnabled) {
      print(
          '[SimpleCommunication] Starting message polling with interval: $_pollInterval');
    }
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _checkForMessages());

    // Start heartbeat
    _startHeartbeat();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_appId != null) {
        html.window.localStorage['app_heartbeat_$_appId'] =
            DateTime.now().millisecondsSinceEpoch.toString();
      }
    });
  }

  void _checkForMessages() {
    // Only check localStorage if not using BroadcastChannel
    if (_useBroadcastChannel) {
      return; // BroadcastChannel handles messages automatically
    }

    // Check all message keys in the queue
    final messageKeys = html.window.localStorage.keys
        .where((k) => k.startsWith(_messageQueuePrefix))
        .toList()
      ..sort(); // Process in order

    for (final key in messageKeys) {
      final data = html.window.localStorage[key];
      if (data != null) {
        try {
          final messageData = jsonDecode(data) as Map<String, dynamic>;
          final message = CommunicationMessage.fromJson(messageData);

          // Check if message is for this app or broadcast
          if (message.target == null || message.target == _appId) {
            if (_logEnabled) {
              print(
                  '[SimpleCommunication] Processing message: ${message.action} with data: ${message.data}');
            }

            // Send acknowledgment
            _sendAcknowledgment(message.id);

            // Emit message
            _messageController.add(message);
            if (_logEnabled) {
              print('[SimpleCommunication] Message emitted to stream');
            }
          } else {
            if (_logEnabled) {
              print('[SimpleCommunication] Message not for this app, skipping');
            }
          }

          // Remove processed message
          html.window.localStorage.remove(key);
          if (_logEnabled) {
            print(
                '[SimpleCommunication] Message removed from localStorage: $key');
          }
        } catch (e) {
          if (_logEnabled) {
            print('[SimpleCommunication] Error parsing message: $e');
          }
          // Remove corrupted message
          html.window.localStorage.remove(key);
        }
      }
    }
  }

  void _checkUrlParams() {
    if (_logEnabled) {
      print('[SimpleCommunication] Checking URL parameters');
    }

    final uri = Uri.parse(html.window.location.href);
    if (uri.queryParameters.containsKey('communicationData')) {
      if (_logEnabled) {
        print(
            '[SimpleCommunication] Found communicationData in URL parameters');
      }

      try {
        final data = jsonDecode(
            Uri.decodeComponent(uri.queryParameters['communicationData']!));
        final message = CommunicationMessage(
          id: _generateMessageId(),
          action: 'urlData',
          data: data as Map<String, dynamic>,
          timestamp: DateTime.now(),
        );

        if (_logEnabled) {
          print(
              '[SimpleCommunication] Created URL data message: ${message.action}');
        }
        _messageController.add(message);

        // Clean URL
        final cleanUrl = uri.replace(queryParameters: {}).toString();
        html.window.history.replaceState(null, '', cleanUrl);
        if (_logEnabled) {
          print('[SimpleCommunication] URL cleaned: $cleanUrl');
        }
      } catch (e) {
        if (_logEnabled) {
          print('[SimpleCommunication] Error parsing URL data: $e');
        }
      }
    } else {
      if (_logEnabled) {
        print(
            '[SimpleCommunication] No communicationData found in URL parameters');
      }
    }
  }

  Future<bool> _sendViaNative(Map<String, dynamic> message) async {
    if (_logEnabled) {
      print('[SimpleCommunication] Attempting native communication');
    }

    try {
      final encodedData = Uri.encodeComponent(jsonEncode(message));
      final customUrl = '$_urlScheme://${message['action']}?data=$encodedData';

      if (_logEnabled) {
        print('[SimpleCommunication] Custom URL: $customUrl');
      }

      // Create a temporary iframe to trigger URL scheme
      final iframe = html.IFrameElement()
        ..src = customUrl
        ..style.display = 'none';

      html.document.body!.append(iframe);
      if (_logEnabled) {
        print('[SimpleCommunication] Iframe created and appended');
      }

      // Remove iframe after a short delay
      await Future.delayed(const Duration(milliseconds: 100));
      iframe.remove();
      if (_logEnabled) {
        print('[SimpleCommunication] Iframe removed');
      }

      return true;
    } catch (e) {
      if (_logEnabled) {
        print('[SimpleCommunication] Native communication failed: $e');
      }
      return false;
    }
  }

  Future<bool> _sendViaWeb(Map<String, dynamic> message) async {
    if (_logEnabled) {
      print('[SimpleCommunication] Sending via web communication: $message');
    }

    try {
      if (_useBroadcastChannel) {
        _channel!.postMessage(message);
        if (_logEnabled) {
          print('[SimpleCommunication] Message sent via BroadcastChannel');
        }
      } else {
        // Use localStorage with queue system
        return await _sendViaLocalStorage(message);
      }
      return true;
    } catch (e) {
      if (_logEnabled) {
        print('[SimpleCommunication] Web communication failed: $e');
      }
      return false;
    }
  }

  /// Send message via localStorage with queue system
  Future<bool> _sendViaLocalStorage(Map<String, dynamic> message) async {
    try {
      // Generate unique message key
      final messageKey = _getNextMessageKey();
      html.window.localStorage[messageKey] = jsonEncode({
        ...message,
        'key': messageKey,
        'created': DateTime.now().millisecondsSinceEpoch,
      });

      if (_logEnabled) {
        print(
            '[SimpleCommunication] Message stored in localStorage with key: $messageKey');
      }

      // Clean up old messages (prevent localStorage bloat)
      _cleanupOldMessages();

      return true;
    } catch (e) {
      if (_logEnabled) {
        print('[SimpleCommunication] localStorage send failed: $e');
      }
      return false;
    }
  }

  /// Generate next message key for queue system
  String _getNextMessageKey() {
    final counter =
        int.parse(html.window.localStorage[_messageCounter] ?? '0') + 1;
    html.window.localStorage[_messageCounter] = counter.toString();
    return '${_messageQueuePrefix}${counter.toString().padLeft(10, '0')}';
  }

  /// Clean up old messages to prevent localStorage bloat
  void _cleanupOldMessages() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final maxAge = const Duration(minutes: 5).inMilliseconds;

    final keysToRemove = <String>[];
    for (final key in html.window.localStorage.keys) {
      if (key.startsWith(_messageQueuePrefix)) {
        try {
          final data = html.window.localStorage[key];
          if (data != null) {
            final messageData = jsonDecode(data) as Map<String, dynamic>;
            final created = messageData['created'] as int? ?? 0;
            if (now - created > maxAge) {
              keysToRemove.add(key);
            }
          }
        } catch (e) {
          keysToRemove.add(key);
        }
      }
    }

    for (final key in keysToRemove) {
      html.window.localStorage.remove(key);
      if (_logEnabled) {
        print('[SimpleCommunication] Cleaned up old message: $key');
      }
    }
  }

  void _sendAcknowledgment(String messageId) {
    if (_logEnabled) {
      print(
          '[SimpleCommunication] Sending acknowledgment for message: $messageId');
    }

    html.window.localStorage['$_ackPrefix$messageId'] = 'true';
    if (_logEnabled) {
      print(
          '[SimpleCommunication] Acknowledgment stored with key: $_ackPrefix$messageId');
    }
  }

  Future<bool> _waitForAcknowledgment(String messageId) async {
    if (_logEnabled) {
      print(
          '[SimpleCommunication] Starting acknowledgment wait for message: $messageId');
    }

    final completer = Completer<bool>();
    final ackKey = '$_ackPrefix$messageId';
    final maxRetries = 3;
    int retryCount = 0;

    Timer? pollTimer;
    Timer? timeoutTimer;

    pollTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (html.window.localStorage[ackKey] != null) {
        if (_logEnabled) {
          print(
              '[SimpleCommunication] Acknowledgment received for message: $messageId');
        }

        html.window.localStorage.remove(ackKey);
        timeoutTimer?.cancel();
        pollTimer?.cancel();
        completer.complete(true);
      }
    });

    timeoutTimer = Timer(_ackTimeout, () {
      pollTimer?.cancel();
      if (retryCount < maxRetries) {
        retryCount++;
        if (_logEnabled) {
          print(
              '[SimpleCommunication] Acknowledgment timeout, retry $retryCount/$maxRetries');
        }
        // Could implement retry logic here if needed
        completer.complete(false);
      } else {
        if (_logEnabled) {
          print(
              '[SimpleCommunication] Acknowledgment failed after $maxRetries attempts');
        }
        completer.complete(false);
      }
    });

    return completer.future;
  }

  String _generateMessageId() {
    final messageId =
        '${DateTime.now().millisecondsSinceEpoch}_${_randomString(6)}';
    if (_logEnabled) {
      print('[SimpleCommunication] Generated message ID: $messageId');
    }
    return messageId;
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(length, (i) => chars[random % chars.length]).join();
  }

  void dispose() {
    if (_logEnabled) {
      print('[SimpleCommunication] Disposing communication bridge');
    }

    _pollTimer?.cancel();
    _heartbeatTimer?.cancel();
    _messageController.close();

    // Remove heartbeat
    if (_appId != null) {
      html.window.localStorage.remove('app_heartbeat_$_appId');
    }

    if (_channel != null) {
      _channel!.close();
    }

    if (_logEnabled) {
      print('[SimpleCommunication] Communication bridge disposed');
    }
  }
}

/// Message class for cross-app communication
class CommunicationMessage {
  final String id;
  final String action;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String? source;
  final String? target;

  const CommunicationMessage({
    required this.id,
    required this.action,
    required this.data,
    required this.timestamp,
    this.source,
    this.target,
  });

  factory CommunicationMessage.fromJson(Map<String, dynamic> json) {
    return CommunicationMessage(
      id: json['id'] as String? ?? '',
      action: json['action'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>? ?? <String, dynamic>{},
      timestamp: DateTime.fromMillisecondsSinceEpoch(
          json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      source: json['source'] as String?,
      target: json['target'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'action': action,
        'data': data,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'source': source,
        'target': target,
      };

  @override
  String toString() {
    return 'CommunicationMessage(id: $id, action: $action, data: $data, timestamp: $timestamp, source: $source, target: $target)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunicationMessage &&
        other.id == id &&
        other.action == action &&
        other.timestamp == timestamp &&
        other.source == source &&
        other.target == target;
  }

  @override
  int get hashCode {
    return Object.hash(id, action, timestamp, source, target);
  }
}

/// Communication type enum
enum CommunicationType {
  /// Automatically choose between native and web communication
  auto,

  /// Force native communication only
  native,

  /// Force web-to-web communication only
  web,
}

/// Helper widget for Flutter apps to easily integrate the communication bridge
class SimpleCommunicationProvider extends StatefulWidget {
  final String appId;
  final Widget child;
  final Function(CommunicationMessage)? onMessage;
  final CommunicationType communicationType;
  final bool enableLogging;
  final String urlScheme;

  const SimpleCommunicationProvider({
    super.key,
    required this.appId,
    required this.child,
    this.onMessage,
    this.communicationType = CommunicationType.auto,
    this.enableLogging = false,
    this.urlScheme = 'simplecommunication',
  });

  @override
  State<SimpleCommunicationProvider> createState() =>
      _SimpleCommunicationProviderState();
}

class _SimpleCommunicationProviderState
    extends State<SimpleCommunicationProvider> {
  final communication = SimpleCommunication();
  StreamSubscription<CommunicationMessage>? _subscription;

  @override
  void initState() {
    super.initState();
    communication.initialize(
      appId: widget.appId,
      communicationType: widget.communicationType,
      enableLogging: widget.enableLogging,
      urlScheme: widget.urlScheme,
    );

    _subscription = communication.messages.listen((message) {
      widget.onMessage?.call(message);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    communication.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

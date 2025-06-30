// main.dart - Mobile-Optimized Flutter Web App for WebView

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:simple_communication/simple_communication.dart';

void main() {
  if (kDebugMode) print('[Main] Starting Flutter app');
  runApp(const MobileFlutterApp());
}

// Message types for display
class MessageItem {
  final String type; // 'sent' or 'received'
  final String action;
  final String data;
  final DateTime timestamp;

  const MessageItem({
    required this.type,
    required this.action,
    required this.data,
    required this.timestamp,
  });
}

class MobileFlutterApp extends StatelessWidget {
  const MobileFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) print('[Main] Building MobileFlutterApp');

    return MaterialApp(
      title: 'Simple Communication Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        // Mobile-optimized theme
        appBarTheme: const AppBarTheme(
          elevation: 1,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48), // Full width buttons
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: SimpleCommunicationProvider(
        appId: 'demo_flutter_app',
        enableLogging: kDebugMode, // Enable logging only in debug mode
        // urlScheme: 'demoapp', // Uncomment to use custom URL scheme 'demoapp://'
        onMessage: (message) {
          if (kDebugMode) {
            print('[Main] Global message received: ${message.action}');
          }
          debugPrint('Global message: ${message.action}');
        },
        child: const MobileHomePage(),
      ),
    );
  }
}

class MobileHomePage extends StatefulWidget {
  const MobileHomePage({super.key});

  @override
  State<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends State<MobileHomePage> {
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  // State
  String? _currentUser;
  bool _isLoading = false;
  final List<MessageItem> _messages = [];
  List<String> _activeApps = [];

  // Store communication instance to avoid context issues
  late final SimpleCommunication _communication;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) print('[Main] MobileHomePage initState called');

    // Get the communication instance from context once
    _communication = SimpleCommunication.instance;

    _setupCommunication();
    _loadSessionData();
    _loadActiveApps();
  }

  void _setupCommunication() {
    if (kDebugMode) print('[Main] Setting up communication message listener');

    _communication.messages.listen((message) {
      if (kDebugMode) {
        print('[Main] Communication message received: ${message.action}');
      }

      setState(() {
        _messages.insert(
          0,
          MessageItem(
            type: 'received',
            action: message.action,
            data: message.data.toString(),
            timestamp: message.timestamp,
          ),
        );
      });

      if (kDebugMode) {
        print(
            '[Main] Message added to history, total messages: ${_messages.length}');
      }

      // Handle specific actions
      switch (message.action) {
        case 'userLogin':
          if (kDebugMode) print('[Main] Handling userLogin action');
          _handleUserLogin(message.data);
          break;
        case 'profileUpdated':
          if (kDebugMode) print('[Main] Handling profileUpdated action');
          _showSnackBar('Profile updated successfully!', isSuccess: true);
          break;
        case 'userProfile':
          if (kDebugMode) print('[Main] Handling userProfile action');
          _showReceivedData('User Profile', message.data);
          break;
        case 'appSettings':
          if (kDebugMode) print('[Main] Handling appSettings action');
          _showReceivedData('App Settings', message.data);
          break;
        case 'deviceInfo':
          if (kDebugMode) print('[Main] Handling deviceInfo action');
          _showReceivedData('Device Info', message.data);
          break;
        case 'sessionUpdate':
          if (kDebugMode) print('[Main] Handling sessionUpdate action');
          _handleSessionUpdate(message.data);
          break;
        case 'sessionCleared':
          if (kDebugMode) print('[Main] Handling sessionCleared action');
          _handleSessionCleared();
          break;
        default:
          if (kDebugMode) print('[Main] Unhandled action: ${message.action}');
      }
    });

    if (kDebugMode) print('[Main] Communication setup complete');
  }

  void _loadSessionData() {
    if (kDebugMode) print('[Main] Loading session data');

    final user = _communication.getSessionData<String>('currentUser');
    if (user != null) {
      if (kDebugMode) print('[Main] Found existing user in session: $user');
      setState(() {
        _currentUser = user;
      });
    } else {
      if (kDebugMode) print('[Main] No existing user found in session');
    }
  }

  void _loadActiveApps() {
    if (kDebugMode) print('[Main] Loading active apps');

    final apps = _communication.getActiveApps();
    setState(() {
      _activeApps = apps;
    });

    if (kDebugMode) print('[Main] Active apps: $_activeApps');
  }

  void _handleUserLogin(Map<String, dynamic> data) {
    if (kDebugMode) print('[Main] Handling user login with data: $data');

    final username = data['username'];
    setState(() {
      _currentUser = username;
    });
    _communication.setSessionData('currentUser', username);
    if (kDebugMode) {
      print('[Main] User logged in and session data saved: $username');
    }
    _showSnackBar('Logged in as $username', isSuccess: true);
  }

  void _handleSessionUpdate(Map<String, dynamic> data) {
    if (kDebugMode) print('[Main] Handling session update: $data');

    final key = data['key'];
    final value = data['value'];

    if (key == 'currentUser') {
      setState(() {
        _currentUser = value;
      });
    }
  }

  void _handleSessionCleared() {
    if (kDebugMode) print('[Main] Handling session cleared');

    setState(() {
      _currentUser = null;
    });

    _showSnackBar('Session cleared by another app');
  }

  void _showReceivedData(String title, Map<String, dynamic> data) {
    if (kDebugMode) {
      print('[Main] Showing received data modal - Title: $title');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      const JsonEncoder.withIndent('  ').convert(data),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendTestMessage() async {
    if (kDebugMode) print('[Main] Sending test message');

    final message = _messageController.text.trim();
    if (message.isEmpty) {
      if (kDebugMode) print('[Main] Test message is empty, showing error');
      _showSnackBar('Please enter a message');
      return;
    }

    if (kDebugMode) print('[Main] Test message content: $message');
    setState(() => _isLoading = true);

    final success = await _communication.sendMessage('testMessage', {
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      'user': _currentUser ?? 'anonymous',
    });

    if (kDebugMode) print('[Main] Test message send result: $success');

    setState(() {
      _isLoading = false;
      if (success) {
        _messages.insert(
          0,
          MessageItem(
            type: 'sent',
            action: 'testMessage',
            data: message,
            timestamp: DateTime.now(),
          ),
        );
        _messageController.clear();
        if (kDebugMode) print('[Main] Test message added to history');
      }
    });

    _showSnackBar(
      success ? 'Message sent!' : 'Failed to send',
      isSuccess: success,
    );
  }

  Future<void> _sendToWebApp() async {
    if (kDebugMode) print('[Main] Sending message to web app');

    final message = _messageController.text.trim();
    if (message.isEmpty) {
      _showSnackBar('Please enter a message');
      return;
    }

    setState(() => _isLoading = true);

    // Send to first available web app, or broadcast if none found
    final targetApp = _activeApps.isNotEmpty ? _activeApps.first : null;

    final success = await _communication.sendMessage(
        'webMessage',
        {
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
          'user': _currentUser ?? 'anonymous',
        },
        targetAppId: targetApp);

    setState(() {
      _isLoading = false;
      if (success) {
        _messages.insert(
          0,
          MessageItem(
            type: 'sent',
            action: 'webMessage',
            data: 'To ${targetApp ?? 'all apps'}: $message',
            timestamp: DateTime.now(),
          ),
        );
        _messageController.clear();
      }
    });

    _showSnackBar(
      success ? 'Message sent to web app!' : 'Failed to send',
      isSuccess: success,
    );
  }

  Future<void> _requestData(String dataType) async {
    if (kDebugMode) print('[Main] Requesting data of type: $dataType');

    setState(() => _isLoading = true);

    await _communication.sendMessage('requestData', {
      'dataType': dataType,
      'userId': _currentUser ?? 'current',
    });

    if (kDebugMode) print('[Main] Data request sent for: $dataType');

    setState(() {
      _isLoading = false;
      _messages.insert(
        0,
        MessageItem(
          type: 'sent',
          action: 'requestData',
          data: dataType,
          timestamp: DateTime.now(),
        ),
      );
    });

    if (kDebugMode) print('[Main] Data request message added to history');
  }

  Future<void> _updateProfile() async {
    if (kDebugMode) print('[Main] Updating profile');

    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      if (kDebugMode) print('[Main] Profile update failed - missing fields');
      _showSnackBar('Please fill all fields');
      return;
    }

    setState(() => _isLoading = true);

    final profileData = {
      'name': _nameController.text,
      'email': _emailController.text,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (kDebugMode) print('[Main] Profile data to send: $profileData');

    final success =
        await _communication.sendMessage('updateProfile', profileData);
    _communication.setSessionData('userProfile', profileData);

    if (kDebugMode) print('[Main] Profile update result: $success');

    setState(() => _isLoading = false);

    if (success) {
      _nameController.clear();
      _emailController.clear();
      if (kDebugMode) {
        print('[Main] Profile update successful, fields cleared');
      }
      _showSnackBar('Profile update sent!', isSuccess: true);
    }
  }

  void _navigateToFlutterFlow() {
    if (kDebugMode) print('[Main] Navigating to FlutterFlow app');

    final params = {
      'user': _currentUser ?? 'guest',
      'returnUrl': Uri.base.toString(),
      'sessionId': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    if (kDebugMode) print('[Main] Navigation parameters: $params');

    _communication.navigateToApp('flutterflow-app', params);
  }

  void _logout() {
    if (kDebugMode) print('[Main] Logging out user: $_currentUser');

    _communication.clearSession();
    setState(() {
      _currentUser = null;
      _messages.clear();
    });

    _communication.sendMessage('logout', {
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (kDebugMode) print('[Main] Logout complete, session cleared');
    _showSnackBar('Logged out successfully');
  }

  void _refreshActiveApps() {
    if (kDebugMode) print('[Main] Refreshing active apps');
    _loadActiveApps();
    _showSnackBar('Active apps refreshed');
  }

  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (kDebugMode) {
      print('[Main] Showing snackbar: $message (success: $isSuccess)');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : null,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showMessageHistory() {
    if (kDebugMode) {
      print('[Main] Showing message history with ${_messages.length} messages');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Message History',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear_all),
                    onPressed: () {
                      if (kDebugMode) print('[Main] Clearing message history');
                      setState(() => _messages.clear());
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isSent = msg.type == 'sent';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: isSent
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              children: [
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        isSent ? Colors.blue : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg.action,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSent
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        msg.data,
                                        style: TextStyle(
                                          color: isSent
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isSent
                                              ? Colors.white70
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) print('[Main] Building MobileHomePage widget');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Communication Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_currentUser != null)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      _currentUser!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (kDebugMode) print('[Main] Menu item selected: $value');

              switch (value) {
                case 'messages':
                  _showMessageHistory();
                  break;
                case 'apps':
                  _refreshActiveApps();
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'messages',
                child: Row(
                  children: [
                    Icon(Icons.history, size: 20),
                    SizedBox(width: 8),
                    Text('Message History'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'apps',
                child: Row(
                  children: [
                    Icon(Icons.apps, size: 20),
                    SizedBox(width: 8),
                    Text('Refresh Active Apps'),
                  ],
                ),
              ),
              if (_currentUser != null)
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Active Apps Card
              if (_activeApps.isNotEmpty)
                Card(
                  elevation: 2,
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.apps, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Active Apps (${_activeApps.length})',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _activeApps
                              .map((app) => Chip(
                                    label: Text(app),
                                    backgroundColor: Colors.green.shade100,
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_activeApps.isNotEmpty) const SizedBox(height: 16),

              // Configuration Info Card
              Card(
                elevation: 2,
                color: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.settings, color: Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Configuration',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildConfigRow('App ID', 'demo_flutter_app'),
                            _buildConfigRow(
                                'URL Scheme', 'simplecommunication://'),
                            _buildConfigRow(
                                'Logging', kDebugMode ? 'Enabled' : 'Disabled'),
                            _buildConfigRow(
                                'Communication', 'Auto (Native + Web)'),
                            _buildConfigRow(
                                'Active Apps', '${_activeApps.length} found'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '💡 Tip: Uncomment urlScheme in main.dart to use custom scheme',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick Actions Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flash_on, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            'Quick Actions',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.person, size: 18),
                            label: const Text('Get Profile'),
                            onPressed: _isLoading
                                ? null
                                : () => _requestData('userProfile'),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.settings, size: 18),
                            label: const Text('Get Settings'),
                            onPressed: _isLoading
                                ? null
                                : () => _requestData('settings'),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.phone_android, size: 18),
                            label: const Text('Device Info'),
                            onPressed: _isLoading
                                ? null
                                : () => _requestData('deviceInfo'),
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.open_in_new, size: 18),
                            label: const Text('FlutterFlow'),
                            onPressed: _navigateToFlutterFlow,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Send Message Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.send, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Send Message',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Enter your message',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.message),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _sendTestMessage,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send),
                              label: Text(
                                  _isLoading ? 'Sending...' : 'Send to Native'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_activeApps.isNotEmpty)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _sendToWebApp,
                                icon: const Icon(Icons.web),
                                label: const Text('Send to Web'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Update Profile Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Update Profile',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _updateProfile,
                        icon: const Icon(Icons.save),
                        label: const Text('Update Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status Card
              if (_messages.isNotEmpty)
                Card(
                  elevation: 2,
                  color: Colors.blue.shade50,
                  child: InkWell(
                    onTap: _showMessageHistory,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.history, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recent Activity',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                Text(
                                  '${_messages.length} messages exchanged',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.blue.shade700,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      // Floating message indicator
      floatingActionButton: _messages.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showMessageHistory,
              label: Text('${_messages.length}'),
              icon: const Icon(Icons.message),
              backgroundColor: Colors.blue,
            )
          : null,
    );
  }

  @override
  void dispose() {
    if (kDebugMode) print('[Main] Disposing MobileHomePage');

    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}

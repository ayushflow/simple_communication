# Simple Communication

A lightweight Flutter package for seamless communication between Flutter web apps and native applications, as well as between multiple Flutter web apps on the same domain.

## Features

- 🌐 **Cross-Platform Communication**: Bridge communication between Flutter web and native apps
- 🔗 **Web-to-Web Communication**: Enable communication between multiple Flutter web apps on the same domain
- 📡 **Modern API Support**: Uses BroadcastChannel API for optimal performance with localStorage fallback
- 🎯 **Targeted Messaging**: Send messages to specific apps or broadcast to all
- 📡 **Auto-Detection**: Automatically chooses the best communication method
- 💾 **Shared Session Management**: Share data across all apps on the same domain
- 🔍 **App Discovery**: Discover other active apps on the same domain
- ✅ **Message Acknowledgment**: Reliable message delivery with acknowledgment system
- 🛡️ **Error Handling**: Robust error handling with fallback mechanisms
- 📝 **Configurable Logging**: Enable/disable console logging for production use
- 🧹 **Memory Management**: Automatic cleanup of old messages and corrupted data
- 🔄 **Queue System**: Support for multiple concurrent messages without overwrites

## Getting Started

### Installation

Add `simple_communication` to your `pubspec.yaml`:

```yaml
dependencies:
  simple_communication: ^1.1.0
```

### Basic Setup

Wrap your app with `SimpleCommunicationProvider`:

```dart
import 'package:simple_communication/simple_communication.dart';
import 'package:flutter/foundation.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SimpleCommunicationProvider(
      appId: 'my_app',
      communicationType: CommunicationType.auto,
      enableLogging: kDebugMode, // Enable logging only in debug mode
      urlScheme: 'myapp', // Custom URL scheme for native communication
      onMessage: (message) {
        print('Received message: ${message.action}');
        // Handle incoming messages
      },
      child: MaterialApp(
        title: 'My App',
        home: HomePage(),
      ),
    );
  }
}
```

## Usage

### Communication Types

The package supports three communication types:

- **`CommunicationType.auto`** (default): Automatically chooses between native and web communication
- **`CommunicationType.native`**: Forces native communication only
- **`CommunicationType.web`**: Forces web-to-web communication only

### Web Communication Methods

The package automatically uses the best available communication method:

1. **BroadcastChannel API** (Primary): Modern, real-time communication for supported browsers
2. **localStorage Queue System** (Fallback): Reliable fallback for older browsers with message queuing

### URL Scheme Configuration

Customize the URL scheme used for native communication:

```dart
// Use custom URL scheme
SimpleCommunicationProvider(
  appId: 'my_app',
  urlScheme: 'myapp', // Will use 'myapp://' instead of 'simplecommunication://'
  child: MyApp(),
)

// Use default URL scheme
SimpleCommunicationProvider(
  appId: 'my_app',
  // urlScheme defaults to 'simplecommunication'
  child: MyApp(),
)
```

**Note**: When using a custom URL scheme, make sure to update your native app configuration accordingly:

#### iOS (Swift)
```swift
// In AppDelegate.swift, change the scheme check:
if url.scheme == "myapp" { // Your custom scheme
    // Handle communication
}
```

#### Android (Kotlin)
```kotlin
// In AndroidManifest.xml, update the intent filter:
<data android:scheme="myapp" /> <!-- Your custom scheme -->
```

### Logging Configuration

The package provides flexible logging options for production and development:

#### **Development with Logging:**
```dart
SimpleCommunicationProvider(
  appId: 'my_app',
  enableLogging: true, // Enable console logging
  child: MyApp(),
)
```

#### **Production without Logging:**
```dart
SimpleCommunicationProvider(
  appId: 'my_app',
  // enableLogging defaults to false
  child: MyApp(),
)
```

#### **Conditional Logging:**
```dart
SimpleCommunicationProvider(
  appId: 'my_app',
  enableLogging: kDebugMode, // Only in debug builds
  child: MyApp(),
)
```

#### **Runtime Logging Control:**
```dart
// Enable/disable logging at runtime
SimpleCommunication.logEnabled = true; // Enable logging
SimpleCommunication.logEnabled = false; // Disable logging
```

### Sending Messages

#### Send to Native App
```dart
// Send a message to the native app
context.communication.sendMessage('userAction', {
  'userId': 123,
  'action': 'login'
});
```

#### Send to Specific Web App
```dart
// Send a message to a specific web app
context.communication.sendMessage('updateData', {
  'data': 'new_value'
}, targetAppId: 'other_app');
```

#### Broadcast to All Apps
```dart
// Broadcast a message to all apps on the same domain
context.communication.sendMessage('notification', {
  'message': 'Hello from my app!'
});
```

### Receiving Messages

#### Using the Provider Callback
```dart
SimpleCommunicationProvider(
  appId: 'my_app',
  onMessage: (message) {
    switch (message.action) {
      case 'userAction':
        handleUserAction(message.data);
        break;
      case 'updateData':
        updateUI(message.data);
        break;
      case 'notification':
        showNotification(message.data['message']);
        break;
    }
  },
  child: MyApp(),
)
```

#### Using Stream
```dart
class _MyWidgetState extends State<MyWidget> {
  StreamSubscription<CommunicationMessage>? _subscription;
  late final SimpleCommunication _communication; // Store instance

  @override
  void initState() {
    super.initState();
    // Get instance once to avoid context issues
    _communication = context.communication;
    
    _subscription = _communication.messages.listen((message) {
      // Handle incoming messages
      print('Received: ${message.action}');
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

#### Using Static Instance (Alternative)
```dart
class _MyWidgetState extends State<MyWidget> {
  StreamSubscription<CommunicationMessage>? _subscription;

  @override
  void initState() {
    super.initState();
    // Use static instance - no context needed
    _subscription = SimpleCommunication.instance.messages.listen((message) {
      // Handle incoming messages
      print('Received: ${message.action}');
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

### Session Management

Share data across all apps on the same domain:

```dart
// Store session data
context.communication.setSessionData('user', {
  'id': 123,
  'name': 'John Doe',
  'email': 'john@example.com'
});

// Retrieve session data
final user = context.communication.getSessionData<Map<String, dynamic>>('user');
if (user != null) {
  print('User: ${user['name']}');
}

// Clear all session data
context.communication.clearSession();
```

### App Discovery

Discover other active apps on the same domain:

```dart
// Get list of active apps
final activeApps = context.communication.getActiveApps();
print('Active apps: $activeApps');

// Send message to all active apps
for (final appId in activeApps) {
  if (appId != 'my_app') {
    context.communication.sendMessage('hello', {
      'from': 'my_app',
      'message': 'Hello from my app!'
    }, targetAppId: appId);
  }
}
```

### Navigation Between Apps

Navigate to another Flutter app with parameters:

```dart
// Navigate to another app with data
context.communication.navigateToApp('other_app', {
  'userId': 123,
  'action': 'view_profile'
});
```

## Advanced Usage

### Custom Message Handling

```dart
class MessageHandler {
  final SimpleCommunication communication;

  MessageHandler(this.communication) {
    communication.messages.listen(_handleMessage);
  }

  void _handleMessage(CommunicationMessage message) {
    switch (message.action) {
      case 'dataSync':
        _handleDataSync(message.data);
        break;
      case 'userUpdate':
        _handleUserUpdate(message.data);
        break;
      case 'logout':
        _handleLogout();
        break;
    }
  }

  void _handleDataSync(Map<String, dynamic> data) {
    // Handle data synchronization
    print('Syncing data: $data');
  }

  void _handleUserUpdate(Map<String, dynamic> data) {
    // Handle user updates
    print('User updated: $data');
  }

  void _handleLogout() {
    // Handle logout across all apps
    communication.clearSession();
    // Navigate to login page
  }
}
```

### Error Handling

```dart
// Send message with error handling
try {
  final success = await context.communication.sendMessage('importantAction', {
    'data': 'critical_data'
  });
  
  if (success) {
    print('Message sent successfully');
  } else {
    print('Failed to send message');
    // Implement fallback logic
  }
} catch (e) {
  print('Error sending message: $e');
}
```

### Best Practices for Async Operations

#### ❌ Avoid: Using context across async gaps
```dart
// This can cause issues if the widget is disposed
Future<void> sendMessage() async {
  final success = await context.communication.sendMessage('action', data);
  // Context might be invalid here!
}
```

#### ✅ Recommended: Store instance in state
```dart
class _MyWidgetState extends State<MyWidget> {
  late final SimpleCommunication _communication;

  @override
  void initState() {
    super.initState();
    _communication = context.communication; // Get once
  }

  Future<void> sendMessage() async {
    final success = await _communication.sendMessage('action', data);
    // Safe to use - no context dependency
  }
}
```

#### ✅ Alternative: Use static instance
```dart
Future<void> sendMessage() async {
  final success = await SimpleCommunication.instance.sendMessage('action', data);
  // No context needed at all
}
```

#### ✅ For one-off operations: Check mounted
```dart
Future<void> sendMessage() async {
  final success = await context.communication.sendMessage('action', data);
  
  if (mounted) { // Check if widget is still mounted
    setState(() {
      // Update UI safely
    });
  }
}
```

### Web-to-Web Communication Example

```dart
// App 1: Sender
class SenderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SimpleCommunicationProvider(
      appId: 'sender_app',
      communicationType: CommunicationType.web, // Force web communication
      enableLogging: true,
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: Text('Sender App')),
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                final success = await context.communication.sendMessage(
                  'dataUpdate',
                  {'value': 'Hello from sender!'},
                  targetAppId: 'receiver_app',
                );
                print('Message sent: $success');
              },
              child: Text('Send to Receiver'),
            ),
          ),
        ),
      ),
    );
  }
}

// App 2: Receiver
class ReceiverApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SimpleCommunicationProvider(
      appId: 'receiver_app',
      communicationType: CommunicationType.web,
      enableLogging: true,
      onMessage: (message) {
        if (message.action == 'dataUpdate') {
          print('Received: ${message.data['value']}');
          // Update UI with received data
        }
      },
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: Text('Receiver App')),
          body: Center(
            child: Text('Waiting for messages...'),
          ),
        ),
      ),
    );
  }
}
```

## Native App Integration

### iOS (Swift)

Add URL scheme handling to your iOS app:

```swift
// In AppDelegate.swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    if url.scheme == "simplecommunication" {
        let action = url.host ?? ""
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        
        if let dataItem = queryItems.first(where: { $0.name == "data" }),
           let dataString = dataItem.value,
           let data = dataString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            
            // Handle the message
            handleCommunicationMessage(action: action, data: json)
            
            // Send acknowledgment
            sendAcknowledgment(messageId: json["id"] as? String ?? "")
        }
        return true
    }
    return false
}

func handleCommunicationMessage(action: String, data: [String: Any]) {
    switch action {
    case "userAction":
        // Handle user action
        break
    case "navigate":
        // Handle navigation
        break
    default:
        break
    }
}

func sendAcknowledgment(messageId: String) {
    // Send acknowledgment back to Flutter web
    // Implementation depends on your setup
}
```

### Android (Kotlin)

Add intent filter to your Android app:

```kotlin
// In AndroidManifest.xml
<activity android:name=".MainActivity">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="simplecommunication" />
    </intent-filter>
</activity>

// In MainActivity.kt
override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    handleIntent(intent)
}

override fun onNewIntent(intent: Intent?) {
    super.onNewIntent(intent)
    handleIntent(intent)
}

private fun handleIntent(intent: Intent?) {
    val data = intent?.data
    if (data?.scheme == "simplecommunication") {
        val action = data.host
        val dataParam = data.getQueryParameter("data")
        
        if (dataParam != null) {
            try {
                val json = JSONObject(dataParam)
                handleCommunicationMessage(action, json)
                sendAcknowledgment(json.optString("id"))
            } catch (e: Exception) {
                Log.e("Communication", "Error parsing message", e)
            }
        }
    }
}

private fun handleCommunicationMessage(action: String?, data: JSONObject) {
    when (action) {
        "userAction" -> {
            // Handle user action
        }
        "navigate" -> {
            // Handle navigation
        }
    }
}

private fun sendAcknowledgment(messageId: String) {
    // Send acknowledgment back to Flutter web
    // Implementation depends on your setup
}
```

## Configuration

### Environment Variables

The package automatically detects the communication environment, but you can force specific behavior:

```dart
// Force web-only communication
SimpleCommunicationProvider(
  appId: 'my_app',
  communicationType: CommunicationType.web,
  child: MyApp(),
)

// Force native-only communication
SimpleCommunicationProvider(
  appId: 'my_app',
  communicationType: CommunicationType.native,
  child: MyApp(),
)
```

## Troubleshooting

### Common Issues

1. **Messages not received**: Ensure both apps are on the same domain for web-to-web communication
2. **Native communication fails**: Verify URL scheme is properly configured in native apps
3. **Session data not shared**: Check that apps are using the same domain and localStorage is available
4. **Logging not working**: Ensure `enableLogging` is set to `true` or use `SimpleCommunication.logEnabled = true`
5. **Old browser compatibility**: The package automatically falls back to localStorage for older browsers

### Debug Mode

Enable debug logging for troubleshooting:

```dart
// Enable logging at runtime
SimpleCommunication.logEnabled = true;

// Or during initialization
SimpleCommunicationProvider(
  appId: 'my_app',
  enableLogging: true,
  child: MyApp(),
)
```

### Production Best Practices

1. **Disable logging in production**:
   ```dart
   enableLogging: kDebugMode, // Only enable in debug builds
   ```

2. **Handle communication failures gracefully**:
   ```dart
   try {
     final success = await context.communication.sendMessage('action', data);
     if (!success) {
       // Implement fallback logic
     }
   } catch (e) {
     // Handle exceptions
   }
   ```

3. **Clean up resources**:
   ```dart
   @override
   void dispose() {
     _subscription?.cancel();
     super.dispose();
   }
   ```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any issues or have questions, please:

1. Check the [troubleshooting](#troubleshooting) section
2. Search existing [issues](https://github.com/yourusername/simple_communication/issues)
3. Create a new issue with detailed information about your problem

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes and version history.

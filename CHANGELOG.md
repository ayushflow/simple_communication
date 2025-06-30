# Changelog

All notable changes to the `simple_communication` package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-06-30

### Added
- **Cross-platform communication**: Bridge communication between Flutter web and native apps
- **Web-to-web communication**: Enable communication between multiple Flutter web apps on the same domain
- **Targeted messaging**: Send messages to specific apps or broadcast to all
- **Auto-detection**: Automatically chooses the best communication method (native vs web)
- **Shared session management**: Share data across all apps on the same domain
- **App discovery**: Discover other active apps on the same domain
- **Message acknowledgment**: Reliable message delivery with acknowledgment system
- **Configurable logging**: Enable/disable console logging for production use
- **Configurable URL scheme**: Customize the URL scheme used for native communication
- **Error handling**: Robust error handling with fallback mechanisms
- **Heartbeat system**: Apps automatically register their presence
- **URL parameter handling**: Clean URL parameter handling for app navigation
- **Resource cleanup**: Proper disposal of timers and streams
- **Type safety**: Full type safety with proper generics and null safety

### Features
- `SimpleCommunication` class for managing cross-app communication
- `SimpleCommunicationProvider` widget for easy integration
- `CommunicationMessage` class for structured message handling
- `CommunicationType` enum for choosing communication method
- Support for three communication types: `auto`, `native`, and `web`
- Runtime logging control with `SimpleCommunication.logEnabled`
- Session data management with `setSessionData`, `getSessionData`, and `clearSession`
- App discovery with `getActiveApps()`
- Navigation between apps with `navigateToApp()`
- Message acknowledgment system for reliable delivery
- Heartbeat system for app presence detection

### Technical Improvements
- Zero Dart analyzer warnings
- Production-ready code with proper error handling
- Configurable logging system (disabled by default for production)
- Proper resource management and cleanup
- Type-safe JSON handling with error recovery
- Efficient polling mechanism for message detection
- Clean URL parameter handling
- Proper disposal of timers and subscriptions
- Context safety improvements for async operations
- Static instance accessor for better patterns

### Documentation
- Comprehensive README with usage examples
- Native app integration guides for iOS and Android
- Troubleshooting section with common issues
- Production best practices
- Web-to-web communication examples
- Error handling patterns

### Breaking Changes
- Renamed package from `flutter_native_bridge` to `simple_communication`
- Updated class names and method signatures
- Changed URL scheme from `nativebridge://` to `simplecommunication://`
- Updated localStorage keys for better isolation

### Migration Guide
If migrating from the previous `flutter_native_bridge` package:

1. **Update dependencies**:
   ```yaml
   dependencies:
     simple_communication: ^1.0.0
   ```

2. **Update imports**:
   ```dart
   import 'package:simple_communication/simple_communication.dart';
   ```

3. **Update class names**:
   - `NativeFlutterBridge` → `SimpleCommunication`
   - `NativeBridgeProvider` → `SimpleCommunicationProvider`
   - `BridgeMessage` → `CommunicationMessage`

4. **Update method calls**:
   - `sendToNative()` → `sendMessage()`
   - `bridge` → `communication`

5. **Update native app URL schemes**:
   - iOS: Change URL scheme from `nativebridge` to `simplecommunication`
   - Android: Update intent filter scheme from `nativebridge` to `simplecommunication`

### Example Migration
```dart
// Old code
NativeBridgeProvider(
  appId: 'my_app',
  onMessage: (message) => print(message.action),
  child: MyApp(),
)

// New code
SimpleCommunicationProvider(
  appId: 'my_app',
  enableLogging: kDebugMode,
  onMessage: (message) => print(message.action),
  child: MyApp(),
)
```

## [0.0.1] - 2025-06-27

### Initial Release
- Basic native-Flutter web communication
- URL scheme-based messaging
- localStorage fallback mechanism
- Session data management
- Basic message acknowledgment

---

## Version History

- **1.0.0**: Production-ready release with web-to-web communication, configurable logging, and improved architecture
- **0.0.1**: Initial prototype with basic native-web communication

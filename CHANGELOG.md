# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2024-07-28

### 🚀 Added
- **BroadcastChannel API Support**: Added modern BroadcastChannel API as the primary communication method for web-to-web communication
- **Message Queue System**: Implemented a queue-based localStorage system to handle multiple concurrent messages without overwrites
- **Automatic Memory Management**: Added automatic cleanup of old messages (5-minute TTL) to prevent localStorage bloat
- **Enhanced Error Handling**: Improved error handling with message corruption detection and cleanup
- **Retry Logic**: Added retry mechanism for acknowledgment system with configurable retry attempts
- **Graceful Degradation**: Automatic fallback from BroadcastChannel to localStorage for older browsers

### 🐛 Fixed
- **Critical localStorage Key Bug**: Fixed the critical bug where apps were writing to one localStorage key (`simple_communication_bridge`) but reading from a different key (`communication_command`), which prevented web-to-web communication from working
- **Message Overwrite Issue**: Fixed issue where multiple messages could overwrite each other in localStorage
- **Memory Leaks**: Fixed potential memory leaks by implementing automatic cleanup of old and corrupted messages
- **Race Conditions**: Improved handling of concurrent message processing to prevent race conditions

### 🔧 Improved
- **Performance**: Significantly improved performance by using BroadcastChannel API instead of polling localStorage
- **Reliability**: Enhanced message delivery reliability with better acknowledgment system
- **Debugging**: Improved logging and error messages for better debugging experience
- **Browser Compatibility**: Better support for older browsers with automatic fallback mechanisms
- **Code Organization**: Better separation of concerns between different communication methods

### 📝 Documentation
- **Updated README**: Added comprehensive documentation for new features and improvements
- **Usage Examples**: Added examples for BroadcastChannel and localStorage fallback scenarios
- **Troubleshooting**: Enhanced troubleshooting section with new common issues and solutions
- **Best Practices**: Added best practices for production use and error handling

### 🔄 Breaking Changes
- None - This release is fully backward compatible

### 🧪 Testing
- **Enhanced Test Coverage**: Added tests for new BroadcastChannel functionality
- **Fallback Testing**: Added tests for localStorage fallback scenarios
- **Error Scenario Testing**: Added tests for message corruption and cleanup scenarios

## [1.0.0] - 2025-06-30

### 🎉 Initial Release
- **Cross-Platform Communication**: Bridge communication between Flutter web and native apps
- **Web-to-Web Communication**: Enable communication between multiple Flutter web apps on the same domain
- **Targeted Messaging**: Send messages to specific apps or broadcast to all
- **Auto-Detection**: Automatically chooses the best communication method
- **Shared Session Management**: Share data across all apps on the same domain
- **App Discovery**: Discover other active apps on the same domain
- **Message Acknowledgment**: Reliable message delivery with acknowledgment system
- **Error Handling**: Robust error handling with fallback mechanisms
- **Configurable Logging**: Enable/disable console logging for production use
- **URL Scheme Configuration**: Customizable URL schemes for native communication
- **Navigation Support**: Navigate between different Flutter web apps with parameters
- **Flutter Widget Integration**: Easy integration with Flutter apps using SimpleCommunicationProvider

---

## Version History

- **1.1.0** (Current): Major improvements with BroadcastChannel API, message queue system, and critical bug fixes
- **1.0.0**: Initial release with basic cross-app communication functionality

## Migration Guide

### From 1.0.0 to 1.1.0

No migration required! Version 1.1.0 is fully backward compatible. The improvements are automatically applied:

- **Automatic BroadcastChannel Detection**: The package will automatically use BroadcastChannel if available
- **Automatic Fallback**: Older browsers will automatically fall back to the improved localStorage system
- **Enhanced Performance**: Better performance without any code changes required

### Recommended Updates

While not required, you can take advantage of new features:

```dart
// Enable logging to see which communication method is being used
SimpleCommunicationProvider(
  appId: 'my_app',
  enableLogging: true,
  child: MyApp(),
)
```

## Support

For issues, questions, or contributions:

1. Check the [troubleshooting section](README.md#troubleshooting) in the README
2. Search existing [issues](https://github.com/yourusername/simple_communication/issues)
3. Create a new issue with detailed information about your problem

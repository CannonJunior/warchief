import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Debug-only log that avoids string interpolation cost in release builds.
///
/// In release mode, [kDebugMode] is a compile-time false constant, so the
/// Dart compiler eliminates both the call and the closure entirely.
void devLog(String Function() message) {
  if (kDebugMode) {
    debugPrint(message());
  }
}

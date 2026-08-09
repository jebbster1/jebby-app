import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Client OS for analytics and auth (`ios` | `android` | `unknown`).
String clientPlatform() {
  if (kIsWeb) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      default:
        return 'unknown';
    }
  }
  if (Platform.isIOS) return 'ios';
  if (Platform.isAndroid) return 'android';
  return 'unknown';
}

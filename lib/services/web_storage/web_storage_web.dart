import 'dart:js_interop' as js;
import 'dart:js_interop_unsafe' as js_util;
import 'package:flutter/foundation.dart';

class WebStorageHelper {
  static void setItem(String key, String value) {
    try {
      final storage = js.globalContext['localStorage'] as js.JSObject?;
      storage?.callMethod('setItem'.toJS, key.toJS, value.toJS);
    } catch (e) {
      debugPrint('[WebStorage] setItem error: $e');
    }
  }

  static String? getItem(String key) {
    try {
      final storage = js.globalContext['localStorage'] as js.JSObject?;
      if (storage != null && storage.has(key)) {
        final val = storage.callMethod<js.JSString?>('getItem'.toJS, key.toJS);
        return val?.toDart;
      }
    } catch (e) {
      debugPrint('[WebStorage] getItem error: $e');
    }
    return null;
  }

  static void removeItem(String key) {
    try {
      final storage = js.globalContext['localStorage'] as js.JSObject?;
      storage?.callMethod('removeItem'.toJS, key.toJS);
    } catch (e) {
      debugPrint('[WebStorage] removeItem error: $e');
    }
  }
}

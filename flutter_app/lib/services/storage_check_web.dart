// ignore_for_file: depend_on_referenced_packages
import 'package:web/web.dart' as web;

bool isLocalStorageAvailable() {
  try {
    final localStorage = web.window.localStorage;
    localStorage.setItem('__storage_test__', 'test');
    localStorage.removeItem('__storage_test__');
    return true;
  } catch (_) {
    return false;
  }
}

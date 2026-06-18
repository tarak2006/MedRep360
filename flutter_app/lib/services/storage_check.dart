import 'storage_check_stub.dart'
    if (dart.library.js_interop) 'storage_check_web.dart';

bool checkStorage() => isLocalStorageAvailable();

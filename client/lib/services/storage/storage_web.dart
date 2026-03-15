import 'package:web/web.dart' as web;

String? getStorageItem(String key) => web.window.localStorage.getItem(key);

void setStorageItem(String key, String value) =>
    web.window.localStorage.setItem(key, value);

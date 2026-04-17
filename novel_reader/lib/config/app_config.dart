/// 後端全局前綴為 `/api`；構建測試包可覆寫：
/// `flutter build apk --dart-define=API_BASE=https://book.kanashortplay.com/api`
class AppConfig {
  AppConfig._();

  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv.replaceAll(RegExp(r'/+$'), '');
    return 'https://book.kanashortplay.com/api';
  }
}

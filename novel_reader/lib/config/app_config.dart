/// 後端全局前綴為 `/api`；構建測試包可覆寫：
/// `flutter build apk --dart-define=API_BASE=https://book.kanashortplay.com/api`
class AppConfig {
  AppConfig._();

  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv.replaceAll(RegExp(r'/+$'), '');
    return 'https://book.kanashortplay.com/api';
  }

  /// 站點根（去掉 `/api`），用於拼 `cover_url` 等相對路徑。
  static String get siteOrigin {
    final b = apiBaseUrl;
    var s = b;
    if (s.endsWith('/api')) {
      s = s.substring(0, s.length - 4);
    } else if (s.endsWith('/api/')) {
      s = s.substring(0, s.length - 5);
    }
    return s.replaceAll(RegExp(r'/+$'), '');
  }

  /// 將後端返回的絕對 URL 或 `/data/...` 相對路徑轉為可請求的完整 URL。
  static String? resolvePublicUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    final p = path.trim();
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    if (p.startsWith('/')) return '$siteOrigin$p';
    return '$siteOrigin/$p';
  }
}

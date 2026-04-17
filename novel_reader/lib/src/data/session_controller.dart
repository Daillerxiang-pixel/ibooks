import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 持久化 JWT；`/api/chapters/*` 等需 Bearer。
class SessionController extends ChangeNotifier {
  static const _kToken = 'ibooks_token';
  static const _kUser = 'ibooks_user_json';

  String? _token;
  Map<String, dynamic>? _user;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  String? get nickname => _user?['nickname'] as String?;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _token = p.getString(_kToken);
    final raw = p.getString(_kUser);
    if (raw != null && raw.isNotEmpty) {
      try {
        _user = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        _user = null;
      }
    }
    notifyListeners();
  }

  Future<void> setSession(String token, Map<String, dynamic> user) async {
    _token = token;
    _user = user;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kToken, token);
    await p.setString(_kUser, jsonEncode(user));
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    await p.remove(_kUser);
    notifyListeners();
  }
}

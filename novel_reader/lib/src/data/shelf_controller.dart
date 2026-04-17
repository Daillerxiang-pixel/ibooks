import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_exception.dart';
import 'ibooks_repository.dart';
import 'session_controller.dart';

/// 書架（收藏）管理：
/// - **未登入**：寫入本地 [SharedPreferences]，無需任何網絡。
/// - **已登入**：以後端為主；同時把本地的合併上去（去重）。
/// - 切換登入態：自動觸發 [merge]/[refresh]。
class ShelfController extends ChangeNotifier {
  ShelfController({required this.repository, required this.session}) {
    session.addListener(_onSessionChanged);
  }

  final IbooksRepository repository;
  final SessionController session;

  static const _kLocalShelf = 'ibooks_local_shelf';

  final List<BookRow> _items = [];
  bool _loading = false;
  String? _lastError;

  List<BookRow> get items => List.unmodifiable(_items);
  bool get isLoading => _loading;
  String? get lastError => _lastError;
  bool contains(int bookId) => _items.any((b) => b.id == bookId);

  /// 應用啟動時呼叫一次：先載本地，再嘗試與服務端對齊。
  Future<void> bootstrap() async {
    await _loadLocal();
    if (session.isLoggedIn) {
      await _syncOnLogin();
    } else {
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (!session.isLoggedIn) {
      await _loadLocal();
      notifyListeners();
      return;
    }
    _setLoading(true);
    try {
      final remote = await repository.shelfList();
      _items
        ..clear()
        ..addAll(remote);
      _lastError = null;
    } on ApiException catch (e) {
      _lastError = e.message;
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addFromBook(BookRow book) async {
    if (contains(book.id)) return;
    _items.insert(0, book);
    notifyListeners();
    if (session.isLoggedIn) {
      try {
        await repository.shelfAdd(book.id);
      } on ApiException catch (e) {
        _lastError = e.message;
        notifyListeners();
      }
    } else {
      await _saveLocal();
    }
  }

  Future<void> remove(int bookId) async {
    _items.removeWhere((b) => b.id == bookId);
    notifyListeners();
    if (session.isLoggedIn) {
      try {
        await repository.shelfRemove(bookId);
      } on ApiException catch (e) {
        _lastError = e.message;
        notifyListeners();
      }
    } else {
      await _saveLocal();
    }
  }

  // ---------------- 內部 ----------------

  Future<void> _onSessionChanged() async {
    if (session.isLoggedIn) {
      await _syncOnLogin();
    } else {
      // 登出後僅展示本地書架（已登入期間不寫本地，所以這裡會把本地舊數據顯示出來）
      await _loadLocal();
      notifyListeners();
    }
  }

  /// 登入後：把本地未上傳的書批量推到雲端，再以雲端列表為準。
  Future<void> _syncOnLogin() async {
    _setLoading(true);
    try {
      final localIds = _items.map((b) => b.id).toSet();
      List<BookRow> remote = const [];
      try {
        remote = await repository.shelfList();
      } on ApiException catch (e) {
        _lastError = e.message;
      }
      final remoteIds = remote.map((b) => b.id).toSet();
      final toUpload = localIds.difference(remoteIds);
      for (final id in toUpload) {
        try {
          await repository.shelfAdd(id);
        } catch (_) {/* 單條失敗忽略，不阻塞合併 */}
      }
      // 合併後以雲端為準（雲端再拉一次最完整）
      try {
        remote = await repository.shelfList();
      } catch (_) {}
      _items
        ..clear()
        ..addAll(remote);
      // 已登入後清空本地待同步快取，避免重複合併
      await _clearLocal();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadLocal() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kLocalShelf);
    _items.clear();
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw);
      if (list is List) {
        for (final e in list) {
          if (e is Map<String, dynamic>) _items.add(BookRow.fromJson(e));
        }
      }
    } catch (_) {/* 損壞的本地數據忽略 */}
  }

  Future<void> _saveLocal() async {
    final p = await SharedPreferences.getInstance();
    final list = _items.map((b) => {
          'id': b.id,
          'title': b.title,
          'author': b.author,
          'cover_url': b.coverUrl,
          'description': b.description,
          'category': b.category,
          'status': b.status,
          'word_count': b.wordCount,
          'chapter_count': b.chapterCount,
        }).toList();
    await p.setString(_kLocalShelf, jsonEncode(list));
  }

  Future<void> _clearLocal() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kLocalShelf);
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  @override
  void dispose() {
    session.removeListener(_onSessionChanged);
    super.dispose();
  }
}

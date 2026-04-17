import '../api/ibooks_api_client.dart';

class BookRow {
  BookRow({
    required this.id,
    required this.title,
    this.author,
    this.coverUrl,
    this.description,
    this.category,
    this.status,
    this.wordCount,
    this.chapterCount,
  });

  final int id;
  final String title;
  final String? author;
  final String? coverUrl;
  final String? description;
  final String? category;
  final String? status;
  final int? wordCount;
  final int? chapterCount;

  factory BookRow.fromJson(Map<String, dynamic> j) {
    return BookRow(
      id: (j['id'] as num).toInt(),
      title: j['title'] as String? ?? '',
      author: j['author'] as String?,
      coverUrl: j['cover_url'] as String?,
      description: j['description'] as String?,
      category: j['category'] as String?,
      status: j['status'] as String?,
      wordCount: (j['word_count'] as num?)?.toInt(),
      chapterCount: (j['chapter_count'] as num?)?.toInt(),
    );
  }
}

class ChapterListItem {
  ChapterListItem({
    required this.id,
    required this.chapterNum,
    required this.title,
    required this.price,
    this.wordCount,
    required this.isFree,
    required this.deliveryMode,
    required this.isEncrypted,
  });

  final int id;
  final int chapterNum;
  final String title;
  final num price;
  final int? wordCount;
  final bool isFree;
  final String deliveryMode;
  final bool isEncrypted;

  factory ChapterListItem.fromJson(Map<String, dynamic> j) {
    return ChapterListItem(
      id: (j['id'] as num).toInt(),
      chapterNum: (j['chapter_num'] as num).toInt(),
      title: j['title'] as String? ?? '',
      price: j['price'] as num? ?? 0,
      wordCount: (j['word_count'] as num?)?.toInt(),
      isFree: j['is_free'] == true,
      deliveryMode: j['delivery_mode'] as String? ?? 'inline',
      isEncrypted: j['is_encrypted'] == true || j['is_encrypted'] == 1,
    );
  }
}

/// 章節正文憑證（與 `ChaptersService` 對齊）。
class ChapterContentPayload {
  ChapterContentPayload({
    required this.deliveryMode,
    required this.id,
    required this.title,
    required this.price,
    this.wordCount,
    this.content,
    this.ossUrls,
    this.isEncrypted,
    this.contentKeyBase64,
    this.preview,
  });

  final String deliveryMode;
  final int id;
  final String title;
  final num price;
  final int? wordCount;
  final String? content;
  final List<String>? ossUrls;
  final bool? isEncrypted;
  final String? contentKeyBase64;
  final String? preview;

  factory ChapterContentPayload.fromJson(Map<String, dynamic> j) {
    List<String>? urls;
    final raw = j['ossUrls'];
    if (raw is List) {
      urls = raw.map((e) => e.toString()).toList();
    }
    return ChapterContentPayload(
      deliveryMode: j['deliveryMode'] as String? ?? 'inline',
      id: (j['id'] as num).toInt(),
      title: j['title'] as String? ?? '',
      price: j['price'] as num? ?? 0,
      wordCount: (j['word_count'] as num?)?.toInt(),
      content: j['content'] as String?,
      ossUrls: urls,
      isEncrypted: j['isEncrypted'] as bool?,
      contentKeyBase64: j['contentKeyBase64'] as String?,
      preview: j['preview'] as String?,
    );
  }
}

class IbooksRepository {
  IbooksRepository(this._api);

  final IbooksApiClient _api;

  Future<List<BookRow>> listBooks() async {
    final data = await _api.get('/books');
    if (data is! List) return [];
    return data.map((e) => BookRow.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BookRow?> bookDetail(int id) async {
    final data = await _api.get('/books/$id');
    if (data is! Map<String, dynamic>) return null;
    return BookRow.fromJson(data);
  }

  Future<List<ChapterListItem>> chaptersForBook(int bookId) async {
    final data = await _api.get('/books/$bookId/chapters');
    if (data is! List) return [];
    return data.map((e) => ChapterListItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ChapterContentPayload> chapterContent(int chapterId) async {
    final data = await _api.get('/chapters/$chapterId');
    if (data is! Map<String, dynamic>) {
      throw StateError('章節資料格式錯誤');
    }
    return ChapterContentPayload.fromJson(data);
  }

  Future<({String token, Map<String, dynamic> user})> register({
    required String phone,
    required String password,
    String? nickname,
  }) async {
    final data = await _api.post('/auth/register', {
      'phone': phone,
      'password': password,
      if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
    });
    return _parseAuthData(data);
  }

  Future<({String token, Map<String, dynamic> user})> login({
    required String phone,
    required String password,
  }) async {
    final data = await _api.post('/auth/login', {
      'phone': phone,
      'password': password,
    });
    return _parseAuthData(data);
  }

  ({String token, Map<String, dynamic> user}) _parseAuthData(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw StateError('認證回應異常');
    }
    final token = data['token'] as String?;
    final u = data['user'];
    if (token == null || token.isEmpty) {
      throw StateError('未取得 token');
    }
    final user = u is Map<String, dynamic> ? u : <String, dynamic>{};
    return (token: token, user: user);
  }
}

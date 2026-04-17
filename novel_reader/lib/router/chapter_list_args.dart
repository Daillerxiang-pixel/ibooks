/// 目錄頁：從閱讀器進入時，返回需恢復閱讀器（對齊原型邏輯）
class ChapterListArgs {
  const ChapterListArgs({
    this.reopenReader = false,
    this.reopenChapterId,
    required this.bookId,
    this.bookTitle = '',
  });

  final bool reopenReader;
  final int? reopenChapterId;
  final int bookId;
  final String bookTitle;
}

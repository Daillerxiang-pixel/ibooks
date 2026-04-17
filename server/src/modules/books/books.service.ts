import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Book } from '../../entities/book.entity';
import { Chapter } from '../../entities/chapter.entity';

@Injectable()
export class BooksService {
  constructor(
    @InjectRepository(Book)
    private bookRepo: Repository<Book>,
    @InjectRepository(Chapter)
    private chapterRepo: Repository<Chapter>,
  ) {}

  async list() {
    const books = await this.bookRepo.find({ where: { is_active: 1 }, order: { created_at: 'DESC' } });
    return { success: true, data: books };
  }

  async detail(id: number) {
    const book = await this.bookRepo.findOne({ where: { id } });
    if (!book) return { success: false, error: '书籍不存在' };
    return { success: true, data: book };
  }

  async chapters(bookId: number) {
    const chapters = await this.chapterRepo.find({
      where: { book_id: bookId },
      order: { chapter_num: 'ASC' },
    });
    return {
      success: true,
      data: chapters.map((ch) => ({
        id: ch.id,
        chapter_num: ch.chapter_num,
        title: ch.title,
        price: ch.price,
        word_count: ch.word_count,
        is_free: Number(ch.price) === 0,
        /** 與 Flutter：正文走 OSS JSON 或舊版庫內 inline */
        delivery_mode: this.hasOssUrls(ch) ? 'oss' : 'inline',
        is_encrypted: ch.content_is_encrypted,
      })),
    };
  }

  private hasOssUrls(ch: Chapter): boolean {
    if (!ch.content_oss_urls) return false;
    try {
      const u = JSON.parse(ch.content_oss_urls) as unknown;
      return Array.isArray(u) && u.length > 0;
    } catch {
      return false;
    }
  }
}

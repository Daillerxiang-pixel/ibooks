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
    return { success: true, data: chapters.map(ch => ({
      id: ch.id,
      chapter_num: ch.chapter_num,
      title: ch.title,
      price: ch.price,
      word_count: ch.word_count,
      is_free: ch.price === 0,
    }))};
  }
}

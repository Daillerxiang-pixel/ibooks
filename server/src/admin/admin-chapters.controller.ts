import { Body, Controller, Delete, Get, Param, Post, Put } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { Book } from '../entities/book.entity';
import { Chapter } from '../entities/chapter.entity';

@Controller('admin/books/:bookId/chapters')
export class AdminChaptersController {
  constructor(
    @InjectRepository(Book) private books: Repository<Book>,
    @InjectRepository(Chapter) private chapters: Repository<Chapter>,
  ) {}

  @Get()
  async list(@Param('bookId') bookId: number) {
    const items = await this.chapters.find({
      where: { book_id: +bookId },
      order: { chapter_num: 'ASC' },
    });
    return { success: true, data: items };
  }

  @Post()
  async create(@Param('bookId') bookId: number, @Body() body: Partial<Chapter>) {
    const created = this.chapters.create({
      book_id: +bookId,
      chapter_num: body.chapter_num ?? 0,
      title: body.title || '新章節',
      content: body.content ?? null,
      content_oss_urls: body.content_oss_urls ?? null,
      content_is_encrypted: body.content_is_encrypted ?? false,
      content_unlock_key_base64: body.content_unlock_key_base64 ?? null,
      price: body.price ?? 0,
      word_count: body.word_count ?? 0,
    });
    const saved = await this.chapters.save(created);
    await this._refreshBookCounts(+bookId);
    return { success: true, data: saved };
  }

  @Put(':id')
  async update(
    @Param('bookId') bookId: number,
    @Param('id') id: number,
    @Body() body: Partial<Chapter>,
  ) {
    const c = await this.chapters.findOne({ where: { id, book_id: +bookId } });
    if (!c) return { success: false, error: '章節不存在' };
    Object.assign(c, body);
    const saved = await this.chapters.save(c);
    await this._refreshBookCounts(+bookId);
    return { success: true, data: saved };
  }

  @Delete(':id')
  async remove(@Param('bookId') bookId: number, @Param('id') id: number) {
    await this.chapters.delete({ id, book_id: +bookId });
    await this._refreshBookCounts(+bookId);
    return { success: true };
  }

  /** 批量價格設置：body = { ids: number[], price: number } */
  @Post('batch-price')
  async batchPrice(
    @Param('bookId') bookId: number,
    @Body() body: { ids?: number[]; price: number; setAll?: boolean },
  ) {
    let target = body.ids ?? [];
    if (body.setAll) {
      const all = await this.chapters.find({ where: { book_id: +bookId } });
      target = all.map((c) => c.id);
    }
    const price = Number(body.price ?? 0);
    if (target.length === 0) return { success: true, data: { updated: 0 } };
    await this.chapters
      .createQueryBuilder()
      .update()
      .set({ price })
      .whereInIds(target)
      .execute();
    return { success: true, data: { updated: target.length } };
  }

  private async _refreshBookCounts(bookId: number) {
    const b = await this.books.findOne({ where: { id: bookId } });
    if (!b) return;
    const list = await this.chapters.find({ where: { book_id: bookId } });
    b.chapter_count = list.length;
    b.word_count = list.reduce((acc, c) => acc + (c.word_count || 0), 0);
    await this.books.save(b);
  }
}

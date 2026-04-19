import { Body, Controller, Delete, Get, Param, Post, Put, Query } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { ILike, Repository } from 'typeorm';

import { Book } from '../entities/book.entity';
import { Chapter } from '../entities/chapter.entity';

@Controller('admin/books')
export class AdminBooksController {
  constructor(
    @InjectRepository(Book) private books: Repository<Book>,
    @InjectRepository(Chapter) private chapters: Repository<Chapter>,
  ) {}

  @Get()
  async list(
    @Query('page') page = '1',
    @Query('size') size = '20',
    @Query('q') q = '',
    @Query('category') category = '',
  ) {
    const take = Math.min(100, parseInt(size as any, 10) || 20);
    const skip = ((parseInt(page as any, 10) || 1) - 1) * take;
    const where: any = {};
    if (q) where.title = ILike(`%${q}%`);
    if (category) where.category = category;

    const [items, total] = await this.books.findAndCount({
      where,
      order: { id: 'DESC' },
      take,
      skip,
    });
    return { success: true, data: { items, total, page: +page, size: take } };
  }

  @Get(':id')
  async detail(@Param('id') id: number) {
    const b = await this.books.findOne({ where: { id } });
    if (!b) return { success: false, error: '書籍不存在' };
    return { success: true, data: b };
  }

  @Post()
  async create(@Body() body: Partial<Book>) {
    const row = this.books.create({
      title: body.title || '未命名書籍',
      author: body.author,
      cover_url: body.cover_url,
      description: body.description,
      category: body.category,
      tags: body.tags,
      status: body.status ?? '连载',
      word_count: body.word_count ?? 0,
      chapter_count: body.chapter_count ?? 0,
      is_active: body.is_active ?? 1,
    });
    const saved = await this.books.save(row);
    return { success: true, data: saved };
  }

  @Put(':id')
  async update(@Param('id') id: number, @Body() body: Partial<Book>) {
    const b = await this.books.findOne({ where: { id } });
    if (!b) return { success: false, error: '書籍不存在' };
    Object.assign(b, body);
    const saved = await this.books.save(b);
    return { success: true, data: saved };
  }

  @Delete(':id')
  async remove(@Param('id') id: number) {
    await this.chapters.delete({ book_id: id });
    await this.books.delete({ id });
    return { success: true };
  }

  /** 切換上下架 */
  @Post(':id/toggle')
  async toggle(@Param('id') id: number) {
    const b = await this.books.findOne({ where: { id } });
    if (!b) return { success: false, error: '書籍不存在' };
    b.is_active = b.is_active ? 0 : 1;
    await this.books.save(b);
    return { success: true, data: { is_active: b.is_active } };
  }
}

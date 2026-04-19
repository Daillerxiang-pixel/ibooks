import { Body, Controller, Delete, Get, Param, Post, Put } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { FeaturedItem, FeaturedSection } from '../entities/featured.entity';

@Controller('admin/featured')
export class AdminFeaturedController {
  constructor(
    @InjectRepository(FeaturedSection) private sections: Repository<FeaturedSection>,
    @InjectRepository(FeaturedItem) private items: Repository<FeaturedItem>,
  ) {}

  @Get('sections')
  async listSections() {
    const list = await this.sections.find({ order: { sort: 'ASC', id: 'ASC' } });
    return { success: true, data: list };
  }

  @Post('sections')
  async createSection(@Body() body: Partial<FeaturedSection>) {
    const s = this.sections.create({
      name: body.name || '新欄位',
      layout: body.layout ?? 'row',
      sort: body.sort ?? 0,
      is_active: body.is_active ?? 1,
    });
    return { success: true, data: await this.sections.save(s) };
  }

  @Put('sections/:id')
  async updateSection(@Param('id') id: number, @Body() body: Partial<FeaturedSection>) {
    const s = await this.sections.findOne({ where: { id } });
    if (!s) return { success: false, error: '欄位不存在' };
    Object.assign(s, body);
    return { success: true, data: await this.sections.save(s) };
  }

  @Delete('sections/:id')
  async removeSection(@Param('id') id: number) {
    await this.items.delete({ section_id: +id });
    await this.sections.delete({ id });
    return { success: true };
  }

  @Get('sections/:id/items')
  async listItems(@Param('id') id: number) {
    const list = await this.items.find({
      where: { section_id: +id },
      order: { sort: 'ASC', id: 'ASC' },
    });
    return { success: true, data: list };
  }

  @Post('sections/:id/items')
  async addItem(@Param('id') id: number, @Body() body: { book_id: number; sort?: number }) {
    const it = this.items.create({
      section_id: +id,
      book_id: body.book_id,
      sort: body.sort ?? 0,
    });
    return { success: true, data: await this.items.save(it) };
  }

  @Delete('items/:itemId')
  async removeItem(@Param('itemId') itemId: number) {
    await this.items.delete({ id: itemId });
    return { success: true };
  }
}

import { Body, Controller, Delete, Get, Param, Post, Put } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { Category } from '../entities/category.entity';

@Controller('admin/categories')
export class AdminCategoriesController {
  constructor(
    @InjectRepository(Category) private repo: Repository<Category>,
  ) {}

  @Get()
  async list() {
    const items = await this.repo.find({ order: { sort: 'ASC', id: 'ASC' } });
    return { success: true, data: items };
  }

  @Post()
  async create(@Body() body: Partial<Category>) {
    const c = this.repo.create({
      name: body.name || '新分類',
      slug: body.slug,
      description: body.description,
      sort: body.sort ?? 0,
      is_active: body.is_active ?? 1,
    });
    return { success: true, data: await this.repo.save(c) };
  }

  @Put(':id')
  async update(@Param('id') id: number, @Body() body: Partial<Category>) {
    const c = await this.repo.findOne({ where: { id } });
    if (!c) return { success: false, error: '分類不存在' };
    Object.assign(c, body);
    return { success: true, data: await this.repo.save(c) };
  }

  @Delete(':id')
  async remove(@Param('id') id: number) {
    await this.repo.delete({ id });
    return { success: true };
  }
}

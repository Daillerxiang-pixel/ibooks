import { Body, Controller, Delete, Get, Param, Post, Put } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { CoinPackage } from '../entities/coin-package.entity';

@Controller('admin/coin-packages')
export class AdminCoinPackagesController {
  constructor(
    @InjectRepository(CoinPackage) private repo: Repository<CoinPackage>,
  ) {}

  @Get()
  async list() {
    const items = await this.repo.find({ order: { sort: 'ASC', id: 'ASC' } });
    return { success: true, data: items };
  }

  @Post()
  async create(@Body() body: Partial<CoinPackage>) {
    const p = this.repo.create({
      name: body.name || '套餐',
      price_cents: body.price_cents ?? 0,
      coin_amount: body.coin_amount ?? 0,
      bonus_coin: body.bonus_coin ?? 0,
      badge: body.badge,
      sort: body.sort ?? 0,
      is_active: body.is_active ?? 1,
    });
    return { success: true, data: await this.repo.save(p) };
  }

  @Put(':id')
  async update(@Param('id') id: number, @Body() body: Partial<CoinPackage>) {
    const p = await this.repo.findOne({ where: { id } });
    if (!p) return { success: false, error: '套餐不存在' };
    Object.assign(p, body);
    return { success: true, data: await this.repo.save(p) };
  }

  @Delete(':id')
  async remove(@Param('id') id: number) {
    await this.repo.delete({ id });
    return { success: true };
  }
}

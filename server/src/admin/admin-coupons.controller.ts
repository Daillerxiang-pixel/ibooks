import { Body, Controller, Delete, Get, Param, Post, Put } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { Coupon } from '../entities/coupon.entity';

@Controller('admin/coupons')
export class AdminCouponsController {
  constructor(@InjectRepository(Coupon) private repo: Repository<Coupon>) {}

  @Get()
  async list() {
    const items = await this.repo.find({ order: { id: 'DESC' } });
    return { success: true, data: items };
  }

  @Post()
  async create(@Body() body: Partial<Coupon>) {
    const c = this.repo.create({
      code: body.code || `CP-${Date.now()}`,
      name: body.name || '優惠券',
      type: body.type ?? 'amount',
      value: Number(body.value ?? 0),
      valid_from: body.valid_from ? new Date(body.valid_from) : null,
      valid_to: body.valid_to ? new Date(body.valid_to) : null,
      max_uses: body.max_uses ?? 0,
      used_count: body.used_count ?? 0,
      is_active: body.is_active ?? 1,
    });
    return { success: true, data: await this.repo.save(c) };
  }

  @Put(':id')
  async update(@Param('id') id: number, @Body() body: Partial<Coupon>) {
    const c = await this.repo.findOne({ where: { id } });
    if (!c) return { success: false, error: '優惠券不存在' };
    Object.assign(c, {
      ...body,
      valid_from: body.valid_from ? new Date(body.valid_from) : c.valid_from,
      valid_to: body.valid_to ? new Date(body.valid_to) : c.valid_to,
    });
    return { success: true, data: await this.repo.save(c) };
  }

  @Delete(':id')
  async remove(@Param('id') id: number) {
    await this.repo.delete({ id });
    return { success: true };
  }
}

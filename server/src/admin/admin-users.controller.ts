import { Controller, Delete, Get, Param, Post, Query, Body } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { ILike, Repository } from 'typeorm';

import { User } from '../entities/user.entity';

@Controller('admin/users')
export class AdminUsersController {
  constructor(@InjectRepository(User) private repo: Repository<User>) {}

  @Get()
  async list(
    @Query('page') page = '1',
    @Query('size') size = '20',
    @Query('q') q = '',
  ) {
    const take = Math.min(100, parseInt(size as any, 10) || 20);
    const skip = ((parseInt(page as any, 10) || 1) - 1) * take;
    const where: any = {};
    if (q) where.phone = ILike(`%${q}%`);
    const [items, total] = await this.repo.findAndCount({
      where,
      order: { created_at: 'DESC' },
      take,
      skip,
      select: ['id', 'phone', 'nickname', 'avatar', 'balance', 'created_at'],
    });
    return { success: true, data: { items, total, page: +page, size: take } };
  }

  /** 調整用戶餘額：body = { delta: number } */
  @Post(':id/balance')
  async adjustBalance(@Param('id') id: string, @Body() body: { delta: number }) {
    const u = await this.repo.findOne({ where: { id } });
    if (!u) return { success: false, error: '用戶不存在' };
    const before = Number(u.balance ?? 0);
    u.balance = before + Number(body.delta ?? 0);
    await this.repo.save(u);
    return { success: true, data: { before, after: u.balance } };
  }

  @Delete(':id')
  async remove(@Param('id') id: string) {
    await this.repo.delete({ id });
    return { success: true };
  }
}

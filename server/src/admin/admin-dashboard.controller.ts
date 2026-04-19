import { Controller, Get } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { Book } from '../entities/book.entity';
import { Chapter } from '../entities/chapter.entity';
import { Order } from '../entities/order.entity';
import { User } from '../entities/user.entity';
import { UserShelf } from '../entities/user-shelf.entity';

@Controller('admin/dashboard')
export class AdminDashboardController {
  constructor(
    @InjectRepository(Book) private books: Repository<Book>,
    @InjectRepository(Chapter) private chapters: Repository<Chapter>,
    @InjectRepository(User) private users: Repository<User>,
    @InjectRepository(Order) private orders: Repository<Order>,
    @InjectRepository(UserShelf) private shelf: Repository<UserShelf>,
  ) {}

  @Get('summary')
  async summary() {
    const [bookCount, chapterCount, userCount, shelfCount] = await Promise.all([
      this.books.count(),
      this.chapters.count(),
      this.users.count(),
      this.shelf.count(),
    ]);
    const paid = await this.orders.find({ where: { status: 'paid' } });
    const revenueCents = paid.reduce((acc, o) => acc + Number(o.amount || 0) * 100, 0);
    return {
      success: true,
      data: {
        bookCount,
        chapterCount,
        userCount,
        shelfCount,
        paidOrders: paid.length,
        revenueYuan: (revenueCents / 100).toFixed(2),
      },
    };
  }

  /** 7 日新增用戶趨勢（簡單按日聚合） */
  @Get('user-trend')
  async userTrend() {
    const days = 7;
    const points: { date: string; count: number }[] = [];
    const all = await this.users.find();
    for (let i = days - 1; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const tag = d.toISOString().slice(0, 10);
      const c = all.filter(
        (u) => (u.created_at?.toISOString?.() ?? '').slice(0, 10) === tag,
      ).length;
      points.push({ date: tag.slice(5), count: c });
    }
    return { success: true, data: points };
  }

  /** 7 日訂單金額趨勢 */
  @Get('revenue-trend')
  async revenueTrend() {
    const days = 7;
    const points: { date: string; amount: number }[] = [];
    const all = await this.orders.find({ where: { status: 'paid' } });
    for (let i = days - 1; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const tag = d.toISOString().slice(0, 10);
      const sum = all
        .filter((o) => (o.pay_time?.toISOString?.() ?? '').slice(0, 10) === tag)
        .reduce((a, b) => a + Number(b.amount || 0), 0);
      points.push({ date: tag.slice(5), amount: Number(sum.toFixed(2)) });
    }
    return { success: true, data: points };
  }
}

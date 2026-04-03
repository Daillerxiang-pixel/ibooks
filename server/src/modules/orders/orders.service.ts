import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { Order } from '../../entities/order.entity.js';
import { UserPurchase } from '../../entities/user-purchase.entity.js';
import { User } from '../../entities/user.entity.js';
import { Chapter } from '../../entities/chapter.entity.js';

@Injectable()
export class OrdersService {
  constructor(
    @InjectRepository(Order)
    private orderRepo: Repository<Order>,
    @InjectRepository(UserPurchase)
    private purchaseRepo: Repository<UserPurchase>,
    @InjectRepository(User)
    private userRepo: Repository<User>,
    @InjectRepository(Chapter)
    private chapterRepo: Repository<Chapter>,
  ) {}

  async create(data: { chapterId?: number; bookId?: number; amount: number }, userId: string) {
    const order = this.orderRepo.create({
      id: uuidv4(),
      user_id: userId,
      type: 'purchase',
      amount: data.amount,
      chapter_id: data.chapterId,
      book_id: data.bookId,
      status: 'pending',
    });
    await this.orderRepo.save(order);
    return { success: true, data: { orderId: order.id, amount: order.amount } };
  }

  async handleNotify(data: { orderId: string; payMethod?: string }) {
    const order = await this.orderRepo.findOne({ where: { id: data.orderId } });
    if (!order) return { success: false, error: '订单不存在' };

    if (order.status !== 'pending') {
      return { success: true, message: '订单已处理' };
    }

    order.status = 'paid';
    order.pay_method = data.payMethod || 'wechat';
    order.pay_time = new Date();
    await this.orderRepo.save(order);

    if (order.chapter_id) {
      const existing = await this.purchaseRepo.findOne({
        where: { user_id: order.user_id, chapter_id: order.chapter_id },
      });
      if (!existing) {
        const purchase = this.purchaseRepo.create({
          user_id: order.user_id,
          chapter_id: order.chapter_id,
        });
        await this.purchaseRepo.save(purchase);
      }
    }

    return { success: true, message: '支付成功' };
  }
}
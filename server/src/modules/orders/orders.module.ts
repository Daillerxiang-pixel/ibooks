import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { OrdersController } from './orders.controller.js';
import { OrdersService } from './orders.service.js';
import { Order } from '../../entities/order.entity.js';
import { UserPurchase } from '../../entities/user-purchase.entity.js';
import { User } from '../../entities/user.entity.js';
import { Chapter } from '../../entities/chapter.entity.js';

@Module({
  imports: [TypeOrmModule.forFeature([Order, UserPurchase, User, Chapter])],
  controllers: [OrdersController],
  providers: [OrdersService],
})
export class OrdersModule {}
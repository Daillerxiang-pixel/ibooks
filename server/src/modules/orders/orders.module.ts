import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { Order } from '../../entities/order.entity';
import { UserPurchase } from '../../entities/user-purchase.entity';
import { User } from '../../entities/user.entity';
import { Chapter } from '../../entities/chapter.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Order, UserPurchase, User, Chapter])],
  controllers: [OrdersController],
  providers: [OrdersService],
})
export class OrdersModule {}

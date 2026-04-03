import { Controller, Post, Body, Req } from '@nestjs/common';
import { OrdersService } from './orders.service';

@Controller('orders')
export class OrdersController {
  constructor(private ordersService: OrdersService) {}

  @Post('create')
  async create(@Body() body: { chapterId?: number; bookId?: number; amount: number }, @Req() req: any) {
    return this.ordersService.create(body, req.userId);
  }

  @Post('notify')
  async notify(@Body() body: any) {
    return this.ordersService.handleNotify(body);
  }
}

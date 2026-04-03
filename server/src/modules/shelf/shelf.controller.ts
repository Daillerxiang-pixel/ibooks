import { Controller, Get, Post, Delete, Param, Req } from '@nestjs/common';
import { ShelfService } from './shelf.service.js';

@Controller('shelf')
export class ShelfController {
  constructor(private shelfService: ShelfService) {}

  @Get()
  async list(@Req() req: any) {
    return this.shelfService.list(req.userId);
  }

  @Post(':bookId')
  async add(@Param('bookId') bookId: number, @Req() req: any) {
    return this.shelfService.add(bookId, req.userId);
  }

  @Delete(':bookId')
  async remove(@Param('bookId') bookId: number, @Req() req: any) {
    return this.shelfService.remove(bookId, req.userId);
  }
}
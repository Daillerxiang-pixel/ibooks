import { Controller, Get, Param } from '@nestjs/common';
import { BooksService } from './books.service';

@Controller('books')
export class BooksController {
  constructor(private booksService: BooksService) {}

  @Get()
  async list() {
    return this.booksService.list();
  }

  @Get(':id')
  async detail(@Param('id') id: number) {
    return this.booksService.detail(id);
  }

  @Get(':id/chapters')
  async chapters(@Param('id') id: number) {
    return this.booksService.chapters(id);
  }
}

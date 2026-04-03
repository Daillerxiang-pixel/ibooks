import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BooksController } from './books.controller.js';
import { BooksService } from './books.service.js';
import { Book } from '../../entities/book.entity.js';
import { Chapter } from '../../entities/chapter.entity.js';

@Module({
  imports: [TypeOrmModule.forFeature([Book, Chapter])],
  controllers: [BooksController],
  providers: [BooksService],
})
export class BooksModule {}
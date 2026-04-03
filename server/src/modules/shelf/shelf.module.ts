import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ShelfController } from './shelf.controller.js';
import { ShelfService } from './shelf.service.js';
import { UserShelf } from '../../entities/user-shelf.entity.js';
import { Book } from '../../entities/book.entity.js';

@Module({
  imports: [TypeOrmModule.forFeature([UserShelf, Book])],
  controllers: [ShelfController],
  providers: [ShelfService],
})
export class ShelfModule {}
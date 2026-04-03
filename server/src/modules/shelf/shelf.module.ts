import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ShelfController } from './shelf.controller';
import { ShelfService } from './shelf.service';
import { UserShelf } from '../../entities/user-shelf.entity';
import { Book } from '../../entities/book.entity';

@Module({
  imports: [TypeOrmModule.forFeature([UserShelf, Book])],
  controllers: [ShelfController],
  providers: [ShelfService],
})
export class ShelfModule {}

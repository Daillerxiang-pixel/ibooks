import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ChaptersController } from './chapters.controller.js';
import { ChaptersService } from './chapters.service.js';
import { Chapter } from '../../entities/chapter.entity.js';
import { UserPurchase } from '../../entities/user-purchase.entity.js';
import { UserShelf } from '../../entities/user-shelf.entity.js';

@Module({
  imports: [TypeOrmModule.forFeature([Chapter, UserPurchase, UserShelf])],
  controllers: [ChaptersController],
  providers: [ChaptersService],
})
export class ChaptersModule {}
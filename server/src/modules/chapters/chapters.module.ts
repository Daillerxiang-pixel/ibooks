import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ChaptersController } from './chapters.controller';
import { ChaptersService } from './chapters.service';
import { Chapter } from '../../entities/chapter.entity';
import { UserPurchase } from '../../entities/user-purchase.entity';
import { UserShelf } from '../../entities/user-shelf.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Chapter, UserPurchase, UserShelf])],
  controllers: [ChaptersController],
  providers: [ChaptersService],
})
export class ChaptersModule {}

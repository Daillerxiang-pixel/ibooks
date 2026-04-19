import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { IngestController } from './ingest.controller';
import { IngestService } from './ingest.service';
import { IngestScheduler } from './ingest.scheduler';
import { IngestSource, IngestTask } from './ingest.entity';
import { Book } from '../../entities/book.entity';
import { Chapter } from '../../entities/chapter.entity';

@Module({
  imports: [TypeOrmModule.forFeature([IngestSource, IngestTask, Book, Chapter])],
  controllers: [IngestController],
  providers: [IngestService, IngestScheduler],
  exports: [IngestService],
})
export class IngestModule {}

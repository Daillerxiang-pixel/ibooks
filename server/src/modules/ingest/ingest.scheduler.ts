import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { IngestService } from './ingest.service';

/**
 * 定时任务：自动检测书籍更新
 * - 每 30 分钟扫描一次，检查是否有源需要更新检查
 * - 每个源按各自的 checkIntervalMinutes 控制
 */
@Injectable()
export class IngestScheduler {
  private readonly logger = new Logger(IngestScheduler.name);

  constructor(private ingestService: IngestService) {}

  @Cron('*/30 * * * *') // 每 30 分钟
  async handleAutoCheck() {
    this.logger.log('定时检查：扫描书籍更新...');
    try {
      await this.ingestService.autoCheckAndFetch();
    } catch (err: any) {
      this.logger.error(`定时检查失败: ${err.message}`);
    }
  }
}

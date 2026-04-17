import { Controller, Get, Post, Delete, Param, Body, Query } from '@nestjs/common';
import { IngestService } from './ingest.service';

@Controller('ingest')
export class IngestController {
  constructor(private ingestService: IngestService) {}

  // ──────────── Source 管理 ────────────

  /** 添加监控源 */
  @Post('sources')
  async addSource(
    @Body() body: { sourceType: string; sourceId: string; autoMonitor?: boolean },
  ) {
    const source = await this.ingestService.addSource(
      body.sourceType,
      body.sourceId,
      body.autoMonitor ?? true,
    );
    return { success: true, data: source };
  }

  /** 列出所有监控源 */
  @Get('sources')
  async listSources() {
    const sources = await this.ingestService.listSources();
    return { success: true, data: sources };
  }

  /** 获取单个源 */
  @Get('sources/:id')
  async getSource(@Param('id') id: number) {
    const source = await this.ingestService.getSource(id);
    return { success: true, data: source };
  }

  /** 删除监控源 */
  @Delete('sources/:id')
  async removeSource(@Param('id') id: number) {
    await this.ingestService.removeSource(id);
    return { success: true };
  }

  // ──────────── 抓取操作 ────────────

  /** 全量抓取 */
  @Post('sources/:id/full-fetch')
  async fullFetch(@Param('id') id: number) {
    const task = await this.ingestService.fullFetch(id);
    return { success: true, data: task, message: '全量抓取已启动（异步），请通过任务接口查看进度' };
  }

  /** 检查更新 */
  @Post('sources/:id/check-update')
  async checkUpdate(@Param('id') id: number) {
    const result = await this.ingestService.checkUpdate(id);
    return { success: true, data: result };
  }

  /** 抓取增量更新 */
  @Post('sources/:id/fetch-update')
  async fetchUpdate(@Param('id') id: number) {
    const task = await this.ingestService.fetchUpdate(id);
    return { success: true, data: task, message: '更新抓取已启动（异步）' };
  }

  // ──────────── 任务查询 ────────────

  /** 查看任务列表 */
  @Get('tasks')
  async listTasks(
    @Query('sourceId') sourceId?: number,
    @Query('limit') limit?: number,
  ) {
    const tasks = await this.ingestService.listTasks(sourceId, limit || 20);
    return { success: true, data: tasks };
  }

  /** 查看单个任务 */
  @Get('tasks/:id')
  async getTask(@Param('id') id: number) {
    const task = await this.ingestService.getTask(id);
    return { success: true, data: task };
  }
}

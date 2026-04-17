import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { IngestSource, IngestTask } from './ingest.entity';
import { Book } from '../../entities/book.entity';
import { Chapter } from '../../entities/chapter.entity';
import { YunshuCrawler } from './crawlers/yunshu-crawler';
import { uploadChapter } from './utils/oss-uploader';
import { buildPlainPayload, buildEncryptedPayload } from './utils/aes-crypto';

const FREE_CHAPTER_COUNT = 10; // 前 10 章免费
const PAID_CHAPTER_PRICE = 5.0;
const AES_KEY = process.env.AES_ENCRYPT_KEY || '+N1jCc/6CsB8VVS45jzIJEK5hhwy8c56/sa0UxbTL7o=';

@Injectable()
export class IngestService {
  private readonly logger = new Logger(IngestService.name);
  private crawler = new YunshuCrawler();

  // 当前正在运行的任务，防止重复
  private runningSources = new Set<number>();

  constructor(
    @InjectRepository(IngestSource)
    private sourceRepo: Repository<IngestSource>,
    @InjectRepository(IngestTask)
    private taskRepo: Repository<IngestTask>,
    @InjectRepository(Book)
    private bookRepo: Repository<Book>,
    @InjectRepository(Chapter)
    private chapterRepo: Repository<Chapter>,
  ) {}

  // ──────────── Source CRUD ────────────

  /** 添加监控源 */
  async addSource(sourceType: string, sourceId: string, autoMonitor = true): Promise<IngestSource> {
    // 检查是否已存在
    const existing = await this.sourceRepo.findOne({
      where: { sourceType, sourceId, isActive: 1 },
    });
    if (existing) {
      throw new Error(`来源已存在: ${sourceType}/${sourceId} (id=${existing.id})`);
    }

    const source = this.sourceRepo.create({
      sourceType,
      sourceId,
      autoMonitor,
      status: 'idle',
      isActive: 1,
    });

    if (sourceType === 'yunshu') {
      source.sourceUrl = `https://www.yunshu.tw/Novel.Asp?Id=${sourceId}`;
    }

    return this.sourceRepo.save(source);
  }

  /** 获取所有监控源 */
  async listSources(): Promise<IngestSource[]> {
    return this.sourceRepo.find({ where: { isActive: 1 }, order: { id: 'ASC' } });
  }

  /** 获取单个源 */
  async getSource(id: number): Promise<IngestSource> {
    const source = await this.sourceRepo.findOne({ where: { id } });
    if (!source) throw new Error(`Source ${id} not found`);
    return source;
  }

  /** 删除监控源（软删） */
  async removeSource(id: number): Promise<void> {
    await this.sourceRepo.update(id, { isActive: 0 });
  }

  // ──────────── 全量抓取 ────────────

  /** 全量抓取一本书 */
  async fullFetch(sourceId: number): Promise<IngestTask> {
    const source = await this.getSource(sourceId);

    if (this.runningSources.has(sourceId)) {
      throw new Error(`源 ${sourceId} 正在抓取中，请勿重复触发`);
    }

    if (source.status === 'fetching') {
      throw new Error(`源 ${sourceId} 状态为 fetching，请勿重复触发`);
    }

    // 创建任务
    const task = this.taskRepo.create({
      sourceId,
      taskType: 'full_fetch',
      status: 'running',
      startedAt: new Date().toISOString(),
      log: '',
    });
    await this.taskRepo.save(task);

    // 标记源为 fetching
    await this.sourceRepo.update(sourceId, { status: 'fetching' });
    this.runningSources.add(sourceId);

    // 异步执行抓取
    this.doFullFetch(source, task).catch((err) => {
      this.logger.error(`FullFetch error for source ${sourceId}: ${err.message}`);
    });

    return task;
  }

  private async doFullFetch(source: IngestSource, task: IngestTask): Promise<void> {
    const log = (msg: string) => {
      this.logger.log(`[Source ${source.id}] ${msg}`);
      task.log = (task.log || '') + `[${new Date().toISOString()}] ${msg}\n`;
    };

    try {
      log('开始抓取书籍信息...');

      // 1. 获取书籍信息 + 章节列表
      const { info, chapters } = await this.crawler.getNovelInfo(source.sourceId);
      log(`书籍: ${info.title}, 共 ${chapters.length} 章`);

      // 更新源信息
      await this.sourceRepo.update(source.id, {
        sourceTitle: info.title,
        sourceChapterCount: chapters.length,
      });

      // 2. 创建或更新 Book 记录
      let book: Book;
      if (source.bookId) {
        book = (await this.bookRepo.findOne({ where: { id: source.bookId } }))!;
      } else {
        book = this.bookRepo.create({
          title: info.title,
          author: info.author || '未知',
          cover_url: info.coverUrl || '',
          description: info.description || '',
          category: info.category || '',
          status: info.status || '连载',
          word_count: 0,
          chapter_count: 0,
          is_active: 1,
        });
        book = await this.bookRepo.save(book);
        await this.sourceRepo.update(source.id, { bookId: book.id });
      }
      log(`Book ID: ${book.id}`);

      // 3. 更新任务总数
      task.totalItems = chapters.length;
      await this.taskRepo.save(task);

      // 4. 逐章抓取 → 上传 OSS → 入库
      let totalWords = 0;
      let processed = 0;
      let failed = 0;

      for (let i = 0; i < chapters.length; i++) {
        const ch = chapters[i];
        const chapterNum = i + 1;
        const isFree = chapterNum <= FREE_CHAPTER_COUNT;

        try {
          // 抓取正文
          const content = await this.crawler.getChapterContent(source.sourceId, ch.sourceId);
          
          if (!content.paragraphs || content.paragraphs.length === 0) {
            log(`第 ${chapterNum} 章 "${ch.title}" 内容为空，跳过`);
            failed++;
            task.failedItems = failed;
            await this.taskRepo.save(task);
            continue;
          }

          // 构建 OSS 内容
          let ossJson: string;
          let preview = '';
          let isEncrypted = false;

          if (isFree) {
            ossJson = buildPlainPayload(ch.title, content.paragraphs);
            isEncrypted = false;
          } else {
            const payload = buildEncryptedPayload(ch.title, content.paragraphs, AES_KEY);
            ossJson = payload.ossJson;
            preview = payload.preview;
            isEncrypted = true;
          }

          // 上传 OSS
          const ossUrl = await uploadChapter(book.id, chapterNum, ossJson);

          // 入库
          const chapterEntity = this.chapterRepo.create({
            book_id: book.id,
            chapter_num: chapterNum,
            title: ch.title,
            content: isFree ? null : preview,
            content_oss_urls: JSON.stringify([ossUrl]),
            content_is_encrypted: isEncrypted,
            content_unlock_key_base64: isFree ? null : AES_KEY,
            price: isFree ? 0 : PAID_CHAPTER_PRICE,
            word_count: content.wordCount,
          });
          await this.chapterRepo.save(chapterEntity);

          totalWords += content.wordCount;
          processed++;

          // 更新进度
          task.processedItems = processed;
          if (processed % 50 === 0 || processed === chapters.length) {
            await this.taskRepo.save(task);
            log(`进度: ${processed}/${chapters.length} 章`);
          }

          // 延迟 0.5s
          if (i < chapters.length - 1) {
            await new Promise((r) => setTimeout(r, 500));
          }
        } catch (err: any) {
          failed++;
          task.failedItems = failed;
          log(`第 ${chapterNum} 章 "${ch.title}" 失败: ${err.message}`);
          await this.taskRepo.save(task);
        }
      }

      // 5. 更新 Book 统计
      await this.bookRepo.update(book.id, {
        chapter_count: processed,
        word_count: totalWords,
      });

      // 6. 更新源和任务状态
      const now = new Date().toISOString();
      await this.sourceRepo.update(source.id, {
        status: 'idle',
        fetchedChapterCount: processed,
        lastFetchAt: now,
        lastCheckAt: now,
      });

      task.status = 'completed';
      task.completedAt = now;
      task.totalItems = chapters.length;
      task.processedItems = processed;
      task.failedItems = failed;
      task.log = (task.log || '') + `[${now}] 完成: ${processed}/${chapters.length} 章, ${failed} 失败\n`;
      await this.taskRepo.save(task);

      log(`全量抓取完成: ${processed}/${chapters.length} 章, ${totalWords} 字`);
    } catch (err: any) {
      log(`全量抓取失败: ${err.message}`);

      await this.sourceRepo.update(source.id, {
        status: 'error',
        lastError: err.message,
      });

      task.status = 'failed';
      task.error = err.message;
      task.completedAt = new Date().toISOString();
      await this.taskRepo.save(task);
    } finally {
      this.runningSources.delete(source.id);
    }
  }

  // ──────────── 更新检测 ────────────

  /** 检查源是否有新章节 */
  async checkUpdate(sourceId: number): Promise<{ hasUpdate: boolean; newChapterCount: number }> {
    const source = await this.getSource(sourceId);
    if (!source.bookId) {
      throw new Error(`源 ${sourceId} 尚未关联本地书籍，请先执行全量抓取`);
    }

    const { chapters } = await this.crawler.getNovelInfo(source.sourceId);
    const remoteCount = chapters.length;

    await this.sourceRepo.update(sourceId, {
      sourceChapterCount: remoteCount,
      lastCheckAt: new Date().toISOString(),
    });

    const newChapters = remoteCount - source.fetchedChapterCount;
    return { hasUpdate: newChapters > 0, newChapterCount: Math.max(0, newChapters) };
  }

  /** 抓取增量更新（新章节） */
  async fetchUpdate(sourceId: number): Promise<IngestTask> {
    const source = await this.getSource(sourceId);
    if (!source.bookId) throw new Error('尚未关联本地书籍');

    if (this.runningSources.has(sourceId)) {
      throw new Error('正在运行中');
    }

    const task = this.taskRepo.create({
      sourceId,
      taskType: 'update_fetch',
      status: 'running',
      startedAt: new Date().toISOString(),
      log: '',
    });
    await this.taskRepo.save(task);

    await this.sourceRepo.update(sourceId, { status: 'fetching' });
    this.runningSources.add(sourceId);

    this.doFetchUpdate(source, task).catch((err) => {
      this.logger.error(`FetchUpdate error: ${err.message}`);
    });

    return task;
  }

  private async doFetchUpdate(source: IngestSource, task: IngestTask): Promise<void> {
    const log = (msg: string) => {
      this.logger.log(`[Update ${source.id}] ${msg}`);
      task.log = (task.log || '') + `[${new Date().toISOString()}] ${msg}\n`;
    };

    try {
      const book = (await this.bookRepo.findOne({ where: { id: source.bookId! } }))!;
      const { chapters } = await this.crawler.getNovelInfo(source.sourceId);

      // 找出本地已有的最大 chapter_num
      const localLatest = await this.chapterRepo.findOne({
        where: { book_id: book.id },
        order: { chapter_num: 'DESC' },
      });
      const localCount = localLatest ? localLatest.chapter_num : 0;
      const newChapters = chapters.slice(localCount);

      if (newChapters.length === 0) {
        log('没有新章节');
        task.status = 'completed';
        task.completedAt = new Date().toISOString();
        task.totalItems = 0;
        await this.taskRepo.save(task);
        await this.sourceRepo.update(source.id, { status: 'idle' });
        return;
      }

      log(`发现 ${newChapters.length} 个新章节 (从第 ${localCount + 1} 章开始)`);
      task.totalItems = newChapters.length;
      await this.taskRepo.save(task);

      let processed = 0;
      let failed = 0;
      let totalWords = 0;

      for (let i = 0; i < newChapters.length; i++) {
        const ch = newChapters[i];
        const chapterNum = localCount + i + 1;
        const isFree = chapterNum <= FREE_CHAPTER_COUNT;

        try {
          const content = await this.crawler.getChapterContent(source.sourceId, ch.sourceId);

          if (!content.paragraphs || content.paragraphs.length === 0) {
            failed++;
            continue;
          }

          let ossJson: string;
          let preview = '';
          let isEncrypted = false;

          if (isFree) {
            ossJson = buildPlainPayload(ch.title, content.paragraphs);
          } else {
            const payload = buildEncryptedPayload(ch.title, content.paragraphs, AES_KEY);
            ossJson = payload.ossJson;
            preview = payload.preview;
            isEncrypted = true;
          }

          const ossUrl = await uploadChapter(book.id, chapterNum, ossJson);

          await this.chapterRepo.save(
            this.chapterRepo.create({
              book_id: book.id,
              chapter_num: chapterNum,
              title: ch.title,
              content: isFree ? null : preview,
              content_oss_urls: JSON.stringify([ossUrl]),
              content_is_encrypted: isEncrypted,
              content_unlock_key_base64: isFree ? null : AES_KEY,
              price: isFree ? 0 : PAID_CHAPTER_PRICE,
              word_count: content.wordCount,
            }),
          );

          totalWords += content.wordCount;
          processed++;

          if (processed % 10 === 0) {
            task.processedItems = processed;
            task.failedItems = failed;
            await this.taskRepo.save(task);
          }

          if (i < newChapters.length - 1) {
            await new Promise((r) => setTimeout(r, 500));
          }
        } catch (err: any) {
          failed++;
          log(`第 ${chapterNum} 章 "${ch.title}" 失败: ${err.message}`);
        }
      }

      // 更新统计
      await this.bookRepo.increment({ id: book.id }, 'chapter_count', processed);
      await this.bookRepo.increment({ id: book.id }, 'word_count', totalWords);

      const now = new Date().toISOString();
      await this.sourceRepo.update(source.id, {
        status: 'idle',
        fetchedChapterCount: (source.fetchedChapterCount || 0) + processed,
        lastFetchAt: now,
        lastCheckAt: now,
      });

      task.status = 'completed';
      task.completedAt = now;
      task.processedItems = processed;
      task.failedItems = failed;
      await this.taskRepo.save(task);

      log(`更新抓取完成: +${processed} 章`);
    } catch (err: any) {
      log(`更新失败: ${err.message}`);
      await this.sourceRepo.update(source.id, { status: 'error', lastError: err.message });
      task.status = 'failed';
      task.error = err.message;
      task.completedAt = new Date().toISOString();
      await this.taskRepo.save(task);
    } finally {
      this.runningSources.delete(source.id);
    }
  }

  // ──────────── 定时任务：自动检测更新 ────────────

  /** 扫描所有需要检查更新的源 */
  async autoCheckAndFetch(): Promise<void> {
    const sources = await this.sourceRepo.find({
      where: { autoMonitor: true, isActive: 1 },
    });

    for (const source of sources) {
      // 跳过正在运行的
      if (this.runningSources.has(source.id) || source.status === 'fetching') continue;

      // 检查是否到了检查时间
      if (source.lastCheckAt) {
        const lastCheck = new Date(source.lastCheckAt).getTime();
        const interval = (source.checkIntervalMinutes || 60) * 60 * 1000;
        if (Date.now() - lastCheck < interval) continue;
      }

      try {
        const { hasUpdate, newChapterCount } = await this.checkUpdate(source.id);
        this.logger.log(`Source ${source.id} (${source.sourceTitle}): ${hasUpdate ? `${newChapterCount} 个新章节` : '无更新'}`);

        if (hasUpdate && source.bookId) {
          await this.fetchUpdate(source.id);
        }
      } catch (err: any) {
        this.logger.error(`AutoCheck error for source ${source.id}: ${err.message}`);
      }
    }
  }

  // ──────────── 任务查询 ────────────

  async listTasks(sourceId?: number, limit = 20): Promise<IngestTask[]> {
    const where: any = {};
    if (sourceId) where.sourceId = sourceId;
    return this.taskRepo.find({ where, order: { id: 'DESC' }, take: limit });
  }

  async getTask(taskId: number): Promise<IngestTask> {
    const task = await this.taskRepo.findOne({ where: { id: taskId } });
    if (!task) throw new Error(`Task ${taskId} not found`);
    return task;
  }
}

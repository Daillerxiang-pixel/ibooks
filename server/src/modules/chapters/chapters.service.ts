import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Chapter } from '../../entities/chapter.entity';
import { UserPurchase } from '../../entities/user-purchase.entity';
import { UserShelf } from '../../entities/user-shelf.entity';

function parseOssUrls(raw: string | null): string[] {
  if (!raw || !raw.trim()) return [];
  try {
    const arr = JSON.parse(raw) as unknown;
    return Array.isArray(arr) ? arr.filter((u) => typeof u === 'string') : [];
  } catch {
    return [];
  }
}

@Injectable()
export class ChaptersService {
  constructor(
    @InjectRepository(Chapter)
    private chapterRepo: Repository<Chapter>,
    @InjectRepository(UserPurchase)
    private purchaseRepo: Repository<UserPurchase>,
    @InjectRepository(UserShelf)
    private shelfRepo: Repository<UserShelf>,
  ) {}

  /**
   * 返回章節閱讀憑證：
   * - 舊版 inline：仍返回 data.content 正文
   * - OSS：返回 ossUrls；付費加密章在已購買時額外返回 contentKeyBase64（與 Flutter 約定一致）
   */
  async getContent(chapterId: number, userId?: string) {
    const chapter = await this.chapterRepo.findOne({ where: { id: chapterId } });
    if (!chapter) return { success: false, error: '章节不存在' };

    const ossUrls = parseOssUrls(chapter.content_oss_urls);
    const useOss = ossUrls.length > 0;

    if (!useOss) {
      return this.getContentLegacyInline(chapter, userId);
    }

    return this.getContentOss(chapter, ossUrls, userId);
  }

  /** 庫內正文（兼容舊數據） */
  private async getContentLegacyInline(chapter: Chapter, userId?: string) {
    const body = chapter.content ?? '';

    if (chapter.price === 0) {
      return {
        success: true,
        data: {
          deliveryMode: 'inline' as const,
          id: chapter.id,
          title: chapter.title,
          price: chapter.price,
          word_count: chapter.word_count,
          content: body,
        },
      };
    }

    if (userId) {
      const purchased = await this.purchaseRepo.findOne({
        where: { user_id: userId, chapter_id: chapter.id },
      });
      if (purchased) {
        return {
          success: true,
          data: {
            deliveryMode: 'inline' as const,
            id: chapter.id,
            title: chapter.title,
            price: chapter.price,
            word_count: chapter.word_count,
            content: body,
          },
        };
      }
    }

    return {
      success: false,
      error: '请购买章节',
      errorCode: 'CHAPTER_LOCKED',
      data: {
        id: chapter.id,
        title: chapter.title,
        price: chapter.price,
        deliveryMode: 'inline' as const,
        preview: body.substring(0, Math.min(200, body.length)),
      },
    };
  }

  /** OSS JSON（明文或加密包由客戶端下載後處理） */
  private async getContentOss(chapter: Chapter, ossUrls: string[], userId?: string) {
    const isFree = Number(chapter.price) === 0;

    if (isFree) {
      return {
        success: true,
        data: {
          deliveryMode: 'oss' as const,
          id: chapter.id,
          title: chapter.title,
          price: chapter.price,
          word_count: chapter.word_count,
          ossUrls,
          isEncrypted: chapter.content_is_encrypted,
          /** 免費且明文 OSS 時為 null；若免費也走加密測試則下發 */
          contentKeyBase64: chapter.content_is_encrypted ? chapter.content_unlock_key_base64 : null,
        },
      };
    }

    if (userId) {
      const purchased = await this.purchaseRepo.findOne({
        where: { user_id: userId, chapter_id: chapter.id },
      });
      if (purchased) {
        return {
          success: true,
          data: {
            deliveryMode: 'oss' as const,
            id: chapter.id,
            title: chapter.title,
            price: chapter.price,
            word_count: chapter.word_count,
            ossUrls,
            isEncrypted: chapter.content_is_encrypted,
            contentKeyBase64: chapter.content_is_encrypted ? chapter.content_unlock_key_base64 : null,
          },
        };
      }
    }

    const previewText = chapter.content ?? '';
    return {
      success: false,
      error: '请购买章节',
      errorCode: 'CHAPTER_LOCKED',
      data: {
        id: chapter.id,
        title: chapter.title,
        price: chapter.price,
        deliveryMode: 'oss' as const,
        preview: previewText.substring(0, Math.min(200, previewText.length)),
      },
    };
  }

  async recordProgress(chapterId: number, position: number, userId: string) {
    const chapter = await this.chapterRepo.findOne({ where: { id: chapterId } });
    if (!chapter) return { success: false, error: '章节不存在' };

    let shelf = await this.shelfRepo.findOne({ where: { user_id: userId, book_id: chapter.book_id } });
    if (!shelf) {
      shelf = this.shelfRepo.create({ user_id: userId, book_id: chapter.book_id, read_progress: '{}' });
    }
    shelf.read_progress = JSON.stringify({ chapterId, position });
    await this.shelfRepo.save(shelf);

    return { success: true, data: { chapterId, position } };
  }
}

import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Chapter } from '../../entities/chapter.entity';
import { UserPurchase } from '../../entities/user-purchase.entity';
import { UserShelf } from '../../entities/user-shelf.entity';

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

  async getContent(chapterId: number, userId?: string) {
    const chapter = await this.chapterRepo.findOne({ where: { id: chapterId } });
    if (!chapter) return { success: false, error: '章节不存在' };

    if (chapter.price === 0) {
      return { success: true, data: chapter };
    }

    if (userId) {
      const purchased = await this.purchaseRepo.findOne({
        where: { user_id: userId, chapter_id: chapterId },
      });
      if (purchased) {
        return { success: true, data: chapter };
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
        preview: chapter.content.substring(0, 200),
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

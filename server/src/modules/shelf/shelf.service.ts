import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserShelf } from '../../entities/user-shelf.entity.js';
import { Book } from '../../entities/book.entity.js';

@Injectable()
export class ShelfService {
  constructor(
    @InjectRepository(UserShelf)
    private shelfRepo: Repository<UserShelf>,
    @InjectRepository(Book)
    private bookRepo: Repository<Book>,
  ) {}

  async list(userId: string) {
    const items = await this.shelfRepo.find({ where: { user_id: userId }, order: { created_at: 'DESC' } });
    const books = await Promise.all(
      items.map(async (item) => {
        const book = await this.bookRepo.findOne({ where: { id: item.book_id } });
        return {
          ...book,
          read_progress: JSON.parse(item.read_progress || '{}'),
          added_at: item.created_at,
        };
      })
    );
    return { success: true, data: books };
  }

  async add(bookId: number, userId: string) {
    const existing = await this.shelfRepo.findOne({ where: { user_id: userId, book_id: bookId } });
    if (existing) {
      return { success: true, message: '已在书架中' };
    }
    const shelf = this.shelfRepo.create({ user_id: userId, book_id: bookId, read_progress: '{}' });
    await this.shelfRepo.save(shelf);
    return { success: true, message: '添加成功' };
  }

  async remove(bookId: number, userId: string) {
    await this.shelfRepo.delete({ user_id: userId, book_id: bookId });
    return { success: true, message: '移除成功' };
  }
}
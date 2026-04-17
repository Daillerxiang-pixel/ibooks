import "reflect-metadata";
import { DataSource } from "typeorm";
import * as path from "path";
import crypto from "crypto";
import { User } from "../src/entities/user.entity.js";
import { Book } from "../src/entities/book.entity.js";
import { Chapter } from "../src/entities/chapter.entity.js";

const AppDataSource = new DataSource({
  type: "better-sqlite3",
  database: path.join(process.cwd(), "data", "ibooks.db"),
  entities: [User, Book, Chapter],
  synchronize: true,
});

async function seed() {
  await AppDataSource.initialize();
  console.log("Database connected");

  const bookRepo = AppDataSource.getRepository(Book);
  const chapterRepo = AppDataSource.getRepository(Chapter);

  // Seed books
  const booksData = [
    { title: "重生之都市修仙", author: "十里剑神", category: "都市", status: "连载", word_count: 186000, chapter_count: 1286 },
    { title: "万古仙穹", author: "观棋", category: "玄幻", status: "完结", word_count: 328000, chapter_count: 856 },
    { title: "逆天邪神", author: "火星引力", category: "玄幻", status: "连载", word_count: 572000, chapter_count: 1523 },
    { title: "斗破苍穹", author: "天蚕土豆", category: "玄幻", status: "完结", word_count: 530000, chapter_count: 1620 },
    { title: "完美世界", author: "辰东", category: "玄幻", status: "完结", word_count: 480000, chapter_count: 1288 },
  ];

  /** 演示用：付費加密章共用一把 DEK（生產環境應每章或每訂單獨立密鑰/KMS） */
  const demoPaidDekBase64 = crypto.randomBytes(32).toString("base64");

  for (const bookData of booksData) {
    const existing = await bookRepo.findOne({ where: { title: bookData.title } });
    if (!existing) {
      const book = bookRepo.create({
        ...bookData,
        cover_url: `https://picsum.photos/seed/${bookData.title}/220/300`,
        description: `一部精彩绝伦的${bookData.category}小说，讲述主角逆袭人生的传奇故事...`,
        tags: [bookData.category, "热血", "爽文"],
        is_active: 1,
      });
      await bookRepo.save(book);
      console.log(`Book created: ${book.title}`);

      // Seed chapters for each book
      for (let i = 1; i <= 10; i++) {
        const isFree = i <= 5;
        const ossUrl = `https://cdn.example.com/ibooks-demo/book-${book.id}/chapter-${i}.json`;
        const chapter = chapterRepo.create({
          book_id: book.id,
          chapter_num: i,
          title: `第${i}章 测试章节`,
          /** 舊版 inline 已廢棄時可全 null；此處付費章保留試讀片段供鎖章提示 */
          content: isFree
            ? null
            : `【付費預覽】第${i}章試讀。購買後請依 OSS 地址下載加密 JSON，並使用 API 返回的 contentKeyBase64 解密。`,
          content_oss_urls: JSON.stringify([ossUrl]),
          content_is_encrypted: !isFree,
          content_unlock_key_base64: isFree ? null : demoPaidDekBase64,
          price: isFree ? 0 : 5,
          word_count: 2000,
        });
        await chapterRepo.save(chapter);
      }
      console.log(`  10 chapters created for ${book.title}`);
    }
  }

  console.log("Seed completed!");
  await AppDataSource.destroy();
}

seed().catch(console.error);
import "reflect-metadata";
import { DataSource } from "typeorm";
import * as path from "path";
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
        const chapter = chapterRepo.create({
          book_id: book.id,
          chapter_num: i,
          title: `第${i}章 测试章节`,
          content: `这是第${i}章的内容。主角在这一章经历了精彩的冒险，遇到了重要的人物，剧情跌宕起伏，扣人心弦...（此处省略2000字）`,
          price: i <= 5 ? 0 : 5,
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
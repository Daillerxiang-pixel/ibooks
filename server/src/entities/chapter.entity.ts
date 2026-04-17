import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne } from 'typeorm';
import { Book } from './book.entity';

@Entity('chapters')
export class Chapter {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'int' })
  book_id: number;

  @ManyToOne(() => Book, book => book.chapters)
  book: Book;

  @Column({ type: 'int' })
  chapter_num: number;

  @Column({ type: 'text' })
  title: string;

  /**
   * 舊版：正文存庫。新版優先使用 OSS（content_oss_urls），此欄可為空。
   */
  @Column({ type: 'text', nullable: true })
  content: string | null;

  /**
   * OSS 上章節正文 JSON 地址列表，JSON 字串陣列，例如：["https://cdn.../ch1.json"]
   */
  @Column({ type: 'text', nullable: true })
  content_oss_urls: string | null;

  /**
   * 付費章節 OSS 包為 AES 加密時為 true；免費一般為 false（明文 JSON）
   */
  @Column({ type: 'boolean', default: false })
  content_is_encrypted: boolean;

  /**
   * 解鎖用密鑰（AES-256 key 的 base64）。僅在已購買/免費且需解密時由 API 下發。
   * 生產環境建議改為 KMS / 按訂單臨時簽發。
   */
  @Column({ type: 'text', nullable: true })
  content_unlock_key_base64: string | null;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  price: number;

  @Column({ type: 'int', default: 0 })
  word_count: number;

  @CreateDateColumn()
  created_at: Date;
}

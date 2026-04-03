import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne } from 'typeorm';
import { Book } from './book.entity.js';

@Entity('chapters')
export class Chapter {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  book_id: number;

  @ManyToOne(() => Book, book => book.chapters)
  book: Book;

  @Column()
  chapter_num: number;

  @Column()
  title: string;

  @Column({ type: 'text' })
  content: string;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  price: number;

  @Column({ default: 0 })
  word_count: number;

  @CreateDateColumn()
  created_at: Date;
}
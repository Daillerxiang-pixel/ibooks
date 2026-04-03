import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne } from 'typeorm';
import { Book } from './book.entity.js';

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

  @Column({ type: 'text' })
  content: string;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  price: number;

  @Column({ type: 'int', default: 0 })
  word_count: number;

  @CreateDateColumn()
  created_at: Date;
}

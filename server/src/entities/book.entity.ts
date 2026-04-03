import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, OneToMany } from 'typeorm';
import { Chapter } from './chapter.entity';

@Entity('books')
export class Book {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'text' })
  title: string;

  @Column({ type: 'text', nullable: true })
  author: string;

  @Column({ type: 'text', nullable: true })
  cover_url: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ type: 'text', nullable: true })
  category: string;

  @Column({ type: 'simple-array', nullable: true })
  tags: string[];

  @Column({ type: 'text', default: '连载' })
  status: string;

  @Column({ type: 'int', default: 0 })
  word_count: number;

  @Column({ type: 'int', default: 0 })
  chapter_count: number;

  @Column({ type: 'int', default: 1 })
  is_active: number;

  @CreateDateColumn()
  created_at: Date;

  @OneToMany(() => Chapter, chapter => chapter.book)
  chapters: Chapter[];
}

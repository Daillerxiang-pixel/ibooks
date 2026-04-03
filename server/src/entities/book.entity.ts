import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, OneToMany } from 'typeorm';
import { Chapter } from './chapter.entity.js';

@Entity('books')
export class Book {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  title: string;

  @Column({ nullable: true })
  author: string;

  @Column({ nullable: true })
  cover_url: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ nullable: true })
  category: string;

  @Column({ type: 'simple-array', nullable: true })
  tags: string[];

  @Column({ default: '连载' })
  status: string;

  @Column({ default: 0 })
  word_count: number;

  @Column({ default: 0 })
  chapter_count: number;

  @Column({ default: 1 })
  is_active: number;

  @CreateDateColumn()
  created_at: Date;

  @OneToMany(() => Chapter, chapter => chapter.book)
  chapters: Chapter[];
}
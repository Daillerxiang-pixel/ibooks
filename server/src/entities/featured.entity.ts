import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

/**
 * 書城首頁推薦欄位（如：本週推薦、編輯精選、完結佳作）。
 */
@Entity('featured_sections')
export class FeaturedSection {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'text' })
  name: string;

  /** banner | row | rank */
  @Column({ type: 'text', default: 'row' })
  layout: string;

  @Column({ type: 'int', default: 0 })
  sort: number;

  @Column({ type: 'int', default: 1 })
  is_active: number;

  @CreateDateColumn()
  created_at: Date;
}

@Entity('featured_items')
export class FeaturedItem {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'int' })
  section_id: number;

  @Column({ type: 'int' })
  book_id: number;

  @Column({ type: 'int', default: 0 })
  sort: number;

  @CreateDateColumn()
  created_at: Date;
}

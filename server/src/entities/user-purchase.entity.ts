import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('user_purchases')
export class UserPurchase {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'text' })
  user_id: string;

  @Column({ type: 'int' })
  chapter_id: number;

  @CreateDateColumn()
  created_at: Date;
}

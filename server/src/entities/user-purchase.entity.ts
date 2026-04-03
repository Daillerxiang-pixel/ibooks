import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('user_purchases')
export class UserPurchase {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  user_id: string;

  @Column()
  chapter_id: number;

  @CreateDateColumn()
  created_at: Date;
}
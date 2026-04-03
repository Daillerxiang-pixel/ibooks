import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('orders')
export class Order {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  user_id: string;

  @Column({ default: 'purchase' })
  type: string;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  amount: number;

  @Column({ default: 'pending' })
  status: string;

  @Column({ nullable: true })
  chapter_id: number;

  @Column({ nullable: true })
  book_id: number;

  @Column({ nullable: true })
  pay_method: string;

  @Column({ nullable: true })
  pay_time: Date;

  @CreateDateColumn()
  created_at: Date;
}
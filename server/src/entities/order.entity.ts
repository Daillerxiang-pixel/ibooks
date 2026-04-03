import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('orders')
export class Order {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'text' })
  user_id: string;

  @Column({ type: 'text', default: 'purchase' })
  type: string;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  amount: number;

  @Column({ type: 'text', default: 'pending' })
  status: string;

  @Column({ type: 'int', nullable: true })
  chapter_id: number;

  @Column({ type: 'int', nullable: true })
  book_id: number;

  @Column({ type: 'text', nullable: true })
  pay_method: string;

  @Column({ type: 'datetime', nullable: true })
  pay_time: Date;

  @CreateDateColumn()
  created_at: Date;
}

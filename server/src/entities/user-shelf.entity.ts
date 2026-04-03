import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('user_shelf')
export class UserShelf {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'text' })
  user_id: string;

  @Column({ type: 'int' })
  book_id: number;

  @Column({ type: 'text', nullable: true })
  read_progress: string;

  @CreateDateColumn()
  created_at: Date;
}

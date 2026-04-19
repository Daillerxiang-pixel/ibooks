import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('admin_users')
export class AdminUser {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'text', unique: true })
  username: string;

  @Column({ type: 'text' })
  password_hash: string;

  /** super | operator */
  @Column({ type: 'text', default: 'operator' })
  role: string;

  @Column({ type: 'int', default: 1 })
  is_active: number;

  @Column({ type: 'datetime', nullable: true })
  last_login_at: Date | null;

  @CreateDateColumn()
  created_at: Date;
}

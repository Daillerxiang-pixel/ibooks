import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

/**
 * 優惠券：
 * - type = 'amount'  ：抵扣固定金額（單位：書幣）
 * - type = 'percent' ：百分比折扣（value = 1~100）
 */
@Entity('coupons')
export class Coupon {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'text', unique: true })
  code: string;

  @Column({ type: 'text' })
  name: string;

  /** amount | percent */
  @Column({ type: 'text', default: 'amount' })
  type: string;

  /** amount: 書幣值；percent: 1-100 */
  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  value: number;

  /** 起始 / 截止；null 表示不限 */
  @Column({ type: 'datetime', nullable: true })
  valid_from: Date | null;

  @Column({ type: 'datetime', nullable: true })
  valid_to: Date | null;

  /** 0 = 不限 */
  @Column({ type: 'int', default: 0 })
  max_uses: number;

  @Column({ type: 'int', default: 0 })
  used_count: number;

  @Column({ type: 'int', default: 1 })
  is_active: number;

  @CreateDateColumn()
  created_at: Date;
}

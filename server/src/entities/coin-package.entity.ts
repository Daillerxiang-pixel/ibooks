import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

/** 充值套餐：付出 [price_cents] / 100 元，得到 [coin_amount] + [bonus_coin] 書幣 */
@Entity('coin_packages')
export class CoinPackage {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'text' })
  name: string;

  /** 售價（分） */
  @Column({ type: 'int' })
  price_cents: number;

  /** 主面值書幣 */
  @Column({ type: 'int' })
  coin_amount: number;

  /** 額外贈送書幣 */
  @Column({ type: 'int', default: 0 })
  bonus_coin: number;

  @Column({ type: 'text', nullable: true })
  badge: string;

  @Column({ type: 'int', default: 0 })
  sort: number;

  @Column({ type: 'int', default: 1 })
  is_active: number;

  @CreateDateColumn()
  created_at: Date;
}

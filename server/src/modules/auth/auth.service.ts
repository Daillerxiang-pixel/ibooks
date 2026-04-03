import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import * as jwt from 'jsonwebtoken';
import { User } from '../../entities/user.entity';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private userRepo: Repository<User>,
  ) {}

  async register(data: { phone: string; password: string; nickname?: string }) {
    const existing = await this.userRepo.findOne({ where: { phone: data.phone } });
    if (existing) {
      return { success: false, error: '手机号已注册' };
    }

    const password_hash = await bcrypt.hash(data.password, 10);
    const user = this.userRepo.create({
      phone: data.phone,
      password_hash,
      nickname: data.nickname || '书虫' + data.phone.slice(-4),
      balance: 0,
    });
    await this.userRepo.save(user);

    const token = this.generateToken(user);
    return { success: true, data: { token, user: this.safeUser(user) } };
  }

  async login(data: { phone: string; password: string }) {
    const user = await this.userRepo.findOne({ where: { phone: data.phone } });
    if (!user || !user.password_hash) {
      return { success: false, error: '手机号或密码错误' };
    }

    const valid = await bcrypt.compare(data.password, user.password_hash);
    if (!valid) {
      return { success: false, error: '手机号或密码错误' };
    }

    const token = this.generateToken(user);
    return { success: true, data: { token, user: this.safeUser(user) } };
  }

  generateToken(user: User) {
    return jwt.sign({ userId: user.id, phone: user.phone }, process.env.JWT_SECRET || 'secret', { expiresIn: '30d' });
  }

  safeUser(user: User) {
    return {
      id: user.id,
      phone: user.phone,
      nickname: user.nickname,
      avatar: user.avatar,
      balance: user.balance,
      created_at: user.created_at,
    };
  }
}

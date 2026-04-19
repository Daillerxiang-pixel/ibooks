import { Injectable, OnModuleInit } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import * as jwt from 'jsonwebtoken';

import { AdminUser } from '../entities/admin-user.entity';

@Injectable()
export class AdminAuthService implements OnModuleInit {
  constructor(
    @InjectRepository(AdminUser)
    private readonly repo: Repository<AdminUser>,
  ) {}

  /** 首次啟動：若無管理員，種子默認 admin / admin123（super 角色）。 */
  async onModuleInit() {
    const total = await this.repo.count();
    if (total === 0) {
      const hash = await bcrypt.hash('admin123', 10);
      await this.repo.save(
        this.repo.create({
          username: 'admin',
          password_hash: hash,
          role: 'super',
        }),
      );
      // eslint-disable-next-line no-console
      console.log('[admin] seeded default admin: admin / admin123');
    }
  }

  async login(username: string, password: string) {
    const u = await this.repo.findOne({ where: { username } });
    if (!u || !u.is_active) {
      return { success: false, error: '帳號不存在或已停用' };
    }
    const ok = await bcrypt.compare(password, u.password_hash);
    if (!ok) return { success: false, error: '密碼錯誤' };
    u.last_login_at = new Date();
    await this.repo.save(u);
    const token = jwt.sign(
      { adminId: u.id, username: u.username, role: u.role },
      process.env.JWT_SECRET || 'secret',
      { expiresIn: '7d' },
    );
    return {
      success: true,
      data: {
        token,
        admin: {
          id: u.id,
          username: u.username,
          role: u.role,
        },
      },
    };
  }

  async profile(adminId: number) {
    const u = await this.repo.findOne({ where: { id: adminId } });
    if (!u) return { success: false, error: '管理員不存在' };
    return {
      success: true,
      data: {
        id: u.id,
        username: u.username,
        role: u.role,
        is_active: u.is_active,
        last_login_at: u.last_login_at,
        created_at: u.created_at,
      },
    };
  }

  async changePassword(adminId: number, oldPwd: string, newPwd: string) {
    const u = await this.repo.findOne({ where: { id: adminId } });
    if (!u) return { success: false, error: '管理員不存在' };
    const ok = await bcrypt.compare(oldPwd, u.password_hash);
    if (!ok) return { success: false, error: '舊密碼錯誤' };
    u.password_hash = await bcrypt.hash(newPwd, 10);
    await this.repo.save(u);
    return { success: true };
  }
}

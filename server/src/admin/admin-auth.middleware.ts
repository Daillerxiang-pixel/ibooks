import { Injectable, NestMiddleware } from '@nestjs/common';
import * as jwt from 'jsonwebtoken';

@Injectable()
export class AdminAuthMiddleware implements NestMiddleware {
  use(req: any, res: any, next: () => void) {
    const auth = req.headers.authorization || '';
    const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
    if (!token) {
      return res.status(401).json({ success: false, error: '未登入（管理後台）' });
    }
    try {
      const payload = jwt.verify(
        token,
        process.env.JWT_SECRET || 'secret',
      ) as { adminId?: number; username?: string; role?: string };
      if (!payload.adminId) {
        return res
          .status(401)
          .json({ success: false, error: 'Token 不是管理員憑證' });
      }
      req.adminId = payload.adminId;
      req.adminUsername = payload.username;
      req.adminRole = payload.role;
      next();
    } catch (_) {
      return res
        .status(401)
        .json({ success: false, error: 'Token 無效或已過期' });
    }
  }
}

import { Injectable, NestMiddleware } from '@nestjs/common';
import * as jwt from 'jsonwebtoken';

@Injectable()
export class AuthMiddleware implements NestMiddleware {
  use(req: any, res: any, next: () => void) {
    const authHeader = req.headers.authorization || '';
    const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;

    if (!token) {
      return res.status(401).json({ success: false, error: '未登录' });
    }

    try {
      const payload = jwt.verify(token, process.env.JWT_SECRET || 'secret') as { userId: string; phone: string };
      req.userId = payload.userId;
      req.userPhone = payload.phone;
      next();
    } catch (err) {
      return res.status(401).json({ success: false, error: 'Token无效或已过期' });
    }
  }
}

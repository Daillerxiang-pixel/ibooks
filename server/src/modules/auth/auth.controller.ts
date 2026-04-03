import { Controller, Post, Body } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('register')
  async register(@Body() body: { phone: string; password: string; nickname?: string }) {
    return this.authService.register(body);
  }

  @Post('login')
  async login(@Body() body: { phone: string; password: string }) {
    return this.authService.login(body);
  }

  @Post('sms')
  async sendSms(@Body() body: { phone: string }) {
    return { success: true, message: '验证码已发送（模拟）', code: '123456' };
  }
}

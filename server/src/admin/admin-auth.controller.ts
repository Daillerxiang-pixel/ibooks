import { Body, Controller, Get, Post, Req } from '@nestjs/common';
import { AdminAuthService } from './admin-auth.service';

@Controller('admin/auth')
export class AdminAuthController {
  constructor(private readonly svc: AdminAuthService) {}

  @Post('login')
  login(@Body() body: { username: string; password: string }) {
    return this.svc.login(body.username, body.password);
  }

  @Get('profile')
  profile(@Req() req: any) {
    return this.svc.profile(req.adminId);
  }

  @Post('change-password')
  changePassword(@Req() req: any, @Body() body: { oldPwd: string; newPwd: string }) {
    return this.svc.changePassword(req.adminId, body.oldPwd, body.newPwd);
  }
}

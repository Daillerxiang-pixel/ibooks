import { Controller, Get, Req } from '@nestjs/common';
import { UserService } from './user.service';

@Controller('user')
export class UserController {
  constructor(private userService: UserService) {}

  @Get()
  async profile(@Req() req: any) {
    return this.userService.profile(req.userId);
  }
}

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserController } from './user.controller.js';
import { UserService } from './user.service.js';
import { User } from '../../entities/user.entity.js';
import { UserPurchase } from '../../entities/user-purchase.entity.js';
import { UserShelf } from '../../entities/user-shelf.entity.js';

@Module({
  imports: [TypeOrmModule.forFeature([User, UserPurchase, UserShelf])],
  controllers: [UserController],
  providers: [UserService],
})
export class UserModule {}
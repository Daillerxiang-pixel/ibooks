import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UserController } from './user.controller';
import { UserService } from './user.service';
import { User } from '../../entities/user.entity';
import { UserPurchase } from '../../entities/user-purchase.entity';
import { UserShelf } from '../../entities/user-shelf.entity';

@Module({
  imports: [TypeOrmModule.forFeature([User, UserPurchase, UserShelf])],
  controllers: [UserController],
  providers: [UserService],
})
export class UserModule {}

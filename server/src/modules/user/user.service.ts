import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../entities/user.entity';
import { UserPurchase } from '../../entities/user-purchase.entity';
import { UserShelf } from '../../entities/user-shelf.entity';

@Injectable()
export class UserService {
  constructor(
    @InjectRepository(User)
    private userRepo: Repository<User>,
    @InjectRepository(UserPurchase)
    private purchaseRepo: Repository<UserPurchase>,
    @InjectRepository(UserShelf)
    private shelfRepo: Repository<UserShelf>,
  ) {}

  async profile(userId: string) {
    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) return { success: false, error: '用户不存在' };

    const purchases = await this.purchaseRepo.count({ where: { user_id: userId } });
    const shelfCount = await this.shelfRepo.count({ where: { user_id: userId } });

    return {
      success: true,
      data: {
        id: user.id,
        phone: user.phone,
        nickname: user.nickname,
        avatar: user.avatar,
        balance: user.balance,
        purchases,
        shelfCount,
        created_at: user.created_at,
      },
    };
  }
}

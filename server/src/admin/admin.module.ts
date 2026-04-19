import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { AdminUser } from '../entities/admin-user.entity';
import { Book } from '../entities/book.entity';
import { Chapter } from '../entities/chapter.entity';
import { Category } from '../entities/category.entity';
import { Coupon } from '../entities/coupon.entity';
import { CoinPackage } from '../entities/coin-package.entity';
import { FeaturedSection, FeaturedItem } from '../entities/featured.entity';
import { Order } from '../entities/order.entity';
import { User } from '../entities/user.entity';
import { UserShelf } from '../entities/user-shelf.entity';

import { AdminAuthService } from './admin-auth.service';
import { AdminAuthController } from './admin-auth.controller';
import { AdminBooksController } from './admin-books.controller';
import { AdminChaptersController } from './admin-chapters.controller';
import { AdminCategoriesController } from './admin-categories.controller';
import { AdminCouponsController } from './admin-coupons.controller';
import { AdminCoinPackagesController } from './admin-coin-packages.controller';
import { AdminUsersController } from './admin-users.controller';
import { AdminFeaturedController } from './admin-featured.controller';
import { AdminDashboardController } from './admin-dashboard.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      AdminUser,
      Book,
      Chapter,
      Category,
      Coupon,
      CoinPackage,
      FeaturedSection,
      FeaturedItem,
      Order,
      User,
      UserShelf,
    ]),
  ],
  controllers: [
    AdminAuthController,
    AdminBooksController,
    AdminChaptersController,
    AdminCategoriesController,
    AdminCouponsController,
    AdminCoinPackagesController,
    AdminUsersController,
    AdminFeaturedController,
    AdminDashboardController,
  ],
  providers: [AdminAuthService],
})
export class AdminModule {}

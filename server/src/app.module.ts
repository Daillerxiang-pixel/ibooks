import { MiddlewareConsumer, Module, NestModule, RequestMethod } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './modules/auth/auth.module';
import { BooksModule } from './modules/books/books.module';
import { ChaptersModule } from './modules/chapters/chapters.module';
import { OrdersModule } from './modules/orders/orders.module';
import { ShelfModule } from './modules/shelf/shelf.module';
import { UserModule } from './modules/user/user.module';
import { AdminModule } from './admin/admin.module';
import { AuthMiddleware } from './middleware/auth.middleware';
import { AdminAuthMiddleware } from './admin/admin-auth.middleware';
import { User } from './entities/user.entity';
import { Book } from './entities/book.entity';
import { Chapter } from './entities/chapter.entity';
import { Order } from './entities/order.entity';
import { UserPurchase } from './entities/user-purchase.entity';
import { UserShelf } from './entities/user-shelf.entity';
import { AdminUser } from './entities/admin-user.entity';
import { Category } from './entities/category.entity';
import { Coupon } from './entities/coupon.entity';
import { CoinPackage } from './entities/coin-package.entity';
import { FeaturedSection, FeaturedItem } from './entities/featured.entity';
import * as path from 'path';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'better-sqlite3',
      database: path.join(process.cwd(), 'data', 'ibooks.db'),
      entities: [
        User,
        Book,
        Chapter,
        Order,
        UserPurchase,
        UserShelf,
        AdminUser,
        Category,
        Coupon,
        CoinPackage,
        FeaturedSection,
        FeaturedItem,
      ],
      synchronize: true,
    }),
    AuthModule,
    BooksModule,
    ChaptersModule,
    OrdersModule,
    ShelfModule,
    UserModule,
    AdminModule,
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    // 用戶鑑權：白名單外 + 非 admin 路徑都需登入
    consumer
      .apply(AuthMiddleware)
      .exclude(
        { path: 'auth/login', method: RequestMethod.POST },
        { path: 'auth/register', method: RequestMethod.POST },
        { path: 'auth/sms', method: RequestMethod.POST },
        { path: 'books', method: RequestMethod.GET },
        { path: 'books/:id', method: RequestMethod.GET },
        { path: 'books/:id/chapters', method: RequestMethod.GET },
        // /api/admin/** 走 AdminAuthMiddleware，這裡也要排除
        { path: 'admin/(.*)', method: RequestMethod.ALL },
        { path: 'admin', method: RequestMethod.ALL },
      )
      .forRoutes('*');

    // 管理員鑑權：除登入外的全部 admin 路徑
    consumer
      .apply(AdminAuthMiddleware)
      .exclude({ path: 'admin/auth/login', method: RequestMethod.POST })
      .forRoutes(
        { path: 'admin/(.*)', method: RequestMethod.ALL },
      );
  }
}

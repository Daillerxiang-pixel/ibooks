import { Module, NestModule, MiddlewareConsumer } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './modules/auth/auth.module.js';
import { BooksModule } from './modules/books/books.module.js';
import { ChaptersModule } from './modules/chapters/chapters.module.js';
import { OrdersModule } from './modules/orders/orders.module.js';
import { ShelfModule } from './modules/shelf/shelf.module.js';
import { UserModule } from './modules/user/user.module.js';
import { AuthMiddleware } from './middleware/auth.middleware.js';
import { User } from './entities/user.entity.js';
import { Book } from './entities/book.entity.js';
import { Chapter } from './entities/chapter.entity.js';
import { Order } from './entities/order.entity.js';
import { UserPurchase } from './entities/user-purchase.entity.js';
import { UserShelf } from './entities/user-shelf.entity.js';
import * as path from 'path';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'better-sqlite3',
      database: path.join(process.cwd(), 'data', 'ibooks.db'),
      entities: [User, Book, Chapter, Order, UserPurchase, UserShelf],
      synchronize: true,
    }),
    AuthModule,
    BooksModule,
    ChaptersModule,
    OrdersModule,
    ShelfModule,
    UserModule,
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(AuthMiddleware)
      .exclude('auth/login', 'auth/register', 'auth/sms', 'books', 'books/(.*)')
      .forRoutes('*');
  }
}
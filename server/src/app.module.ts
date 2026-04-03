import { Module, NestModule, MiddlewareConsumer } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './modules/auth/auth.module';
import { BooksModule } from './modules/books/books.module';
import { ChaptersModule } from './modules/chapters/chapters.module';
import { OrdersModule } from './modules/orders/orders.module';
import { ShelfModule } from './modules/shelf/shelf.module';
import { UserModule } from './modules/user/user.module';
import { AuthMiddleware } from './middleware/auth.middleware';
import { User } from './entities/user.entity';
import { Book } from './entities/book.entity';
import { Chapter } from './entities/chapter.entity';
import { Order } from './entities/order.entity';
import { UserPurchase } from './entities/user-purchase.entity';
import { UserShelf } from './entities/user-shelf.entity';
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

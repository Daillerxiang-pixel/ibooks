import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/browse_history_screen.dart';
import '../screens/catlist_screen.dart';
import '../screens/chapterlist_screen.dart';
import '../screens/coin_purchase_screen.dart';
import '../screens/consume_log_screen.dart';
import '../screens/coupon_list_screen.dart';
import '../screens/detail_screen.dart';
import '../screens/login_screen.dart';
import '../screens/reader_screen.dart';
import '../screens/recharge_orders_screen.dart';
import '../screens/search_screen.dart';
import '../screens/tabs/category_tab.dart';
import '../screens/tabs/home_tab.dart';
import '../screens/tabs/profile_tab.dart';
import '../screens/tabs/shelf_tab.dart';
import '../screens/vip_purchase_screen.dart';
import '../shell/main_shell.dart';
import 'chapter_list_args.dart';

abstract final class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter create() {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const MainShell(),
        ),
        GoRoute(
          path: '/detail',
          redirect: (context, state) => '/',
        ),
        GoRoute(
          path: '/reader',
          redirect: (context, state) => '/',
        ),
        GoRoute(
          path: '/login',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final red = state.uri.queryParameters['redirect'];
            return LoginScreen(redirectTo: red);
          },
        ),
        GoRoute(
          path: '/search',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/catlist',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final raw = state.uri.queryParameters['cat'] ?? '都市';
            final cat = Uri.decodeComponent(raw);
            return CatlistScreen(categoryName: cat);
          },
        ),
        GoRoute(
          path: '/detail/:bookId',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['bookId'] ?? '') ?? 0;
            return DetailScreen(bookId: id);
          },
        ),
        GoRoute(
          path: '/chapterlist/:bookId',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final bookId = int.tryParse(state.pathParameters['bookId'] ?? '') ?? 0;
            final extra = state.extra;
            final args = extra is ChapterListArgs
                ? extra
                : ChapterListArgs(bookId: bookId);
            return ChapterListScreen(
              bookId: bookId,
              bookTitle: args.bookTitle,
              reopenReaderOnPop: args.reopenReader,
              reopenChapterId: args.reopenChapterId,
            );
          },
        ),
        GoRoute(
          path: '/reader/:chapterId',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final chapterId = int.tryParse(state.pathParameters['chapterId'] ?? '') ?? 0;
            final bookId = int.tryParse(state.uri.queryParameters['bookId'] ?? '') ?? 0;
            return ReaderScreen(chapterId: chapterId, bookId: bookId);
          },
        ),
        GoRoute(
          path: '/vippurchase',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const VipPurchaseScreen(),
        ),
        GoRoute(
          path: '/coinpurchase',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const CoinPurchaseScreen(),
        ),
        GoRoute(
          path: '/consumelog',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const ConsumeLogScreen(),
        ),
        GoRoute(
          path: '/rechargeorders',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const RechargeOrdersScreen(),
        ),
        GoRoute(
          path: '/browsehistory',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const BrowseHistoryScreen(),
        ),
        GoRoute(
          path: '/couponlist',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const CouponListScreen(),
        ),
      ],
    );
  }

  /// 供 IndexedStack 子頁使用（避免循環 import）
  static Widget tabForIndex(int i) {
    switch (i) {
      case 0:
        return const ShelfTab();
      case 1:
        return const HomeTab();
      case 2:
        return const CategoryTab();
      case 3:
        return const ProfileTab();
      default:
        return const HomeTab();
    }
  }
}

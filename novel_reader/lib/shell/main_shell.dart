import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../theme/app_layout.dart';
import '../theme/ibooks_colors.dart';
import '../widgets/ibooks_shell_header.dart';
import '../widgets/ibooks_tab_bar.dart';

/// 主殼：內容區限寬保留兩側內邊距；底部 TabBar 全寬，背景與整體一致。
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 1;

  static const _titles = ['書架', '書城', '分類', '我的'];
  static const _subs = [
    '最近閱讀 · 收藏',
    '精選 · 推薦 · 付費閱讀',
    '題材瀏覽 · 快速找書',
    '會員 · 帳戶 · 訂單',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IbColors.bg,
      body: Column(
        children: [
          // 內容區：最大寬限制 + 兩側 gutter，但**不再畫邊框**
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxW = math.min(
                  AppLayout.contentMaxWidth,
                  constraints.maxWidth - AppLayout.screenGutter * 2,
                );
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxW),
                    child: Column(
                      children: [
                        IbShellHeader(
                          title: _titles[_tab],
                          subtitle: _subs[_tab],
                          onSearch: () => context.push('/search'),
                        ),
                        Expanded(
                          child: IndexedStack(
                            index: _tab,
                            children: [
                              AppRouter.tabForIndex(0),
                              AppRouter.tabForIndex(1),
                              AppRouter.tabForIndex(2),
                              AppRouter.tabForIndex(3),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // 底部 TabBar：橫鋪全屏，背景與整體一致
          IbTabBar(
            currentIndex: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
        ],
      ),
    );
  }
}

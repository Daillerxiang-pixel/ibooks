import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../theme/ibooks_colors.dart';
import '../widgets/ibooks_shell_header.dart';
import '../widgets/ibooks_tab_bar.dart';

/// 主殼：max-width 420、底部四 Tab（對齊原型）
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            decoration: BoxDecoration(
              color: IbColors.bg,
              boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 0)],
              border: Border.all(color: IbColors.line),
            ),
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
                IbTabBar(
                  currentIndex: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

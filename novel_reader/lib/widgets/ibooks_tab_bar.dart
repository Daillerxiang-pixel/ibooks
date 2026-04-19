import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/ibooks_colors.dart';

/// 底部 TabBar：與整體背景一致，橫鋪全屏；安全區同色。
/// 圖標使用 Material 體系：未選中 outlined / 選中 filled。
class IbTabBar extends StatelessWidget {
  const IbTabBar({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  static const _items = <_TabSpec>[
    _TabSpec(active: Icons.collections_bookmark, idle: Icons.collections_bookmark_outlined, label: '書架'),
    _TabSpec(active: Icons.menu_book, idle: Icons.menu_book_outlined, label: '書城'),
    _TabSpec(active: Icons.dashboard, idle: Icons.dashboard_outlined, label: '分類'),
    _TabSpec(active: Icons.person, idle: Icons.person_outline, label: '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: IbColors.bg,
        border: Border(top: BorderSide(color: IbColors.line)),
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.zero,
        child: SizedBox(
          height: 58,
          child: Row(
            children: List.generate(_items.length, (i) {
              final on = i == currentIndex;
              final c = on ? IbColors.accent : IbColors.inkMuted;
              return Expanded(
                child: InkWell(
                  onTap: () => onChanged(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(on ? _items[i].active : _items[i].idle, size: 22, color: c),
                      const SizedBox(height: 2),
                      Text(
                        _items[i].label,
                        style: GoogleFonts.notoSansTc(
                          fontSize: 10.5,
                          fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                          color: c,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({required this.active, required this.idle, required this.label});
  final IconData active;
  final IconData idle;
  final String label;
}

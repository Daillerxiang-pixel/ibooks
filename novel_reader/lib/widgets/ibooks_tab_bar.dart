import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/ibooks_colors.dart';

class IbTabBar extends StatelessWidget {
  const IbTabBar({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  static const _items = <({String icon, String label})>[
    (icon: '📚', label: '書架'),
    (icon: '📖', label: '書城'),
    (icon: '🗂', label: '分類'),
    (icon: '👤', label: '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF7FFFCF7),
        border: Border(top: BorderSide(color: IbColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(_items.length, (i) {
              final on = i == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onChanged(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_items[i].icon, style: const TextStyle(fontSize: 18.4)),
                      const SizedBox(height: 1),
                      Text(
                        _items[i].label,
                        style: GoogleFonts.notoSansTc(
                          fontSize: 9.3,
                          fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                          color: on ? IbColors.accent : IbColors.inkMuted,
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

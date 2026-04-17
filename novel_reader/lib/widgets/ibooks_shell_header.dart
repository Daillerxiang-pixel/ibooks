import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/ibooks_colors.dart';

/// 對齊原型 `.top-bar`：品牌 + 副標 + 搜尋
class IbShellHeader extends StatelessWidget {
  const IbShellHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onSearch,
  });

  final String title;
  final String subtitle;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: IbColors.bg.withOpacity(0.94),
        border: const Border(bottom: BorderSide(color: IbColors.line)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.notoSerifTc(
                        fontSize: 16.8,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: IbColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.notoSansTc(
                        fontSize: 9.6,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.6,
                        color: IbColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: IbColors.bgCard,
                borderRadius: BorderRadius.circular(11),
                elevation: 1,
                shadowColor: Colors.black26,
                child: InkWell(
                  borderRadius: BorderRadius.circular(11),
                  onTap: onSearch,
                  child: const SizedBox(
                    width: 38,
                    height: 38,
                    child: Center(child: Text('🔍', style: TextStyle(fontSize: 16))),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

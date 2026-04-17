import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/ibooks_colors.dart';

/// 子頁：頂欄返回 + 主標 + 副標（對齊原型 sub-page）
class IbSubpageScaffold extends StatelessWidget {
  const IbSubpageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    this.bottom,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final Widget body;
  final Widget? bottom;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IbColors.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 12, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Text('‹', style: TextStyle(fontSize: 28, height: 1)),
                        padding: EdgeInsets.zero,
                        onPressed: onBack ?? () => context.pop(),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.notoSansTc(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: IbColors.ink,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: GoogleFonts.notoSansTc(
                                fontSize: 11,
                                color: IbColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                  child: body,
                ),
              ),
              if (bottom != null) bottom!,
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_layout.dart';
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
      body: LayoutBuilder(
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
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 6, 8, 6),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: '返回',
                            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                            color: IbColors.ink,
                            onPressed: onBack ?? () => context.pop(),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: GoogleFonts.notoSansTc(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w700,
                                    color: IbColors.ink,
                                    height: 1.2,
                                  ),
                                ),
                                if (subtitle.isNotEmpty)
                                  Text(
                                    subtitle,
                                    style: GoogleFonts.notoSansTc(
                                      fontSize: 11,
                                      color: IbColors.inkMuted,
                                      height: 1.4,
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
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                      child: body,
                    ),
                  ),
                  if (bottom != null) bottom!,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/ibooks_colors.dart';

/// 統一的「錯誤 / 空狀態」展示組件。
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.cloud_off_outlined,
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: IbColors.inkMuted.withOpacity(0.6), size: 36),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansTc(
              fontSize: 13,
              color: IbColors.inkMuted,
              height: 1.5,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('重試'),
            ),
          ],
        ],
      ),
    );
  }
}

/// 「接口未提供」佔位（功能待後端實現）
class ApiUnavailableState extends StatelessWidget {
  const ApiUnavailableState({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      icon: Icons.api_outlined,
      message: '$label\n後端尚未提供對應 API，待接入後此頁將顯示真實數據。',
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../router/chapter_list_args.dart';
import '../../theme/ibooks_colors.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4A3530), Color(0xFF6B4538)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Color(0x141A1A1A), blurRadius: 14)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text('讀', style: GoogleFonts.notoSansTc(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('海外讀者 · 可綁定手機', style: GoogleFonts.notoSansTc(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('付費閱讀 · 儲值與會員', style: GoogleFonts.notoSansTc(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.9))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('帳戶餘額（書幣）', style: GoogleFonts.notoSansTc(fontSize: 10.5, color: Colors.white70)),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text('1,280', style: GoogleFonts.notoSansTc(fontSize: 26, fontWeight: FontWeight.w800, color: const Color(0xFFFFE566))),
                              const SizedBox(width: 4),
                              Text('書幣', style: GoogleFonts.notoSansTc(fontSize: 12, color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '可用於解鎖付費章節；儲值或活動贈送會增加餘額。',
                            style: GoogleFonts.notoSansTc(fontSize: 10.5, height: 1.4, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('上次更新', style: GoogleFonts.notoSansTc(fontSize: 10.5, color: Colors.white70)),
                        Text('剛剛', style: GoogleFonts.notoSansTc(fontSize: 10.5, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE566),
                        foregroundColor: IbColors.ink,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => context.push('/coinpurchase'),
                      child: Text('儲值', style: GoogleFonts.notoSansTc(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => context.push('/consumelog'),
                      child: Text('消費記錄', style: GoogleFonts.notoSansTc(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: () => context.push('/vippurchase'),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF5A3558), Color(0xFF8B4A6E)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: Color(0x141A1A1A), blurRadius: 12)],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                  child: Text('5', style: GoogleFonts.notoSansTc(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('包月優惠套餐', style: GoogleFonts.notoSansTc(color: Colors.white, fontWeight: FontWeight.w700)),
                      Text('進入購買頁查看說明', style: GoogleFonts.notoSansTc(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
                const Text('›', style: TextStyle(color: Colors.white, fontSize: 22)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _MenuTile(icon: '📋', title: '我的訂單', onTap: () => context.push('/rechargeorders')),
        _MenuTile(icon: '🎁', title: '優惠券', trailing: '活動', onTap: () => context.push('/couponlist')),
        _MenuTile(icon: '🕘', title: '瀏覽記錄', onTap: () => context.push('/browsehistory')),
        _MenuTile(icon: '⚙', title: '帳號與安全', onTap: () {}),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.title, this.trailing, required this.onTap});

  final String icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: const BoxDecoration(color: IbColors.bgCard, boxShadow: [BoxShadow(color: Color(0x141A1A1A), blurRadius: 8)]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: GoogleFonts.notoSansTc(fontSize: 13.5))),
                if (trailing != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(trailing!, style: GoogleFonts.notoSansTc(fontSize: 11.5, color: IbColors.accent, fontStyle: FontStyle.normal)),
                  ),
                Text('›', style: TextStyle(color: IbColors.inkMuted.withValues(alpha: 0.5))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

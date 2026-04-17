import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/ibooks_colors.dart';
import '../widgets/ibooks_subpage_scaffold.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IbSubpageScaffold(
      title: '搜尋',
      subtitle: '書名 · 作者 · 標籤',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: IbColors.bgCard, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x141A1A1A), blurRadius: 8)]),
            child: Row(
              children: [
                Text('🔍', style: TextStyle(fontSize: 16, color: IbColors.ink.withOpacity(0.45))),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '搜尋書名、作者、標籤…',
                      hintStyle: GoogleFonts.notoSansTc(fontSize: 13.5, color: IbColors.inkMuted),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('熱搜', style: GoogleFonts.notoSansTc(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ['霸總', '港風', '穿越', '付費榜']
                .map((t) => Chip(label: Text(t, style: GoogleFonts.notoSansTc(fontSize: 11.5)), backgroundColor: IbColors.bgCard))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('搜尋歷史', style: GoogleFonts.notoSansTc(fontSize: 14, fontWeight: FontWeight.w700)),
              Text('清除', style: GoogleFonts.notoSansTc(fontSize: 12, color: IbColors.accent)),
            ],
          ),
          const SizedBox(height: 8),
          _hist('霓虹深處的約定', () => context.push('/detail')),
          _hist('港風 言情', () => context.push('/detail')),
        ],
      ),
    );
  }

  Widget _hist(String t, VoidCallback onTap) {
    return Material(
      color: IbColors.bgCard,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t, style: GoogleFonts.notoSansTc(fontSize: 13.5)),
              const Text('›', style: TextStyle(color: IbColors.inkMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

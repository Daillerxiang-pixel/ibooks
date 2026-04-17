import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/ibooks_colors.dart';

class SectionTitleRow extends StatelessWidget {
  const SectionTitleRow({
    super.key,
    required this.title,
    this.trailing,
    this.marginTop = 0,
  });

  final String title;
  final Widget? trailing;
  final double marginTop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: marginTop, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.notoSansTc(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: IbColors.ink,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class HintLine extends StatelessWidget {
  const HintLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.notoSansTc(
          fontSize: 10.5,
          height: 1.45,
          color: IbColors.inkMuted,
        ),
      ),
    );
  }
}

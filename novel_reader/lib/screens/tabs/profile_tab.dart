import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../src/api/api_exception.dart';
import '../../src/data/ibooks_repository.dart';
import '../../src/data/session_controller.dart';
import '../../theme/ibooks_colors.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  UserProfile? _profile;
  String? _err;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = context.read<SessionController>();
      s.addListener(_onSessionChange);
      _onSessionChange();
    });
  }

  @override
  void dispose() {
    context.read<SessionController>().removeListener(_onSessionChange);
    super.dispose();
  }

  void _onSessionChange() {
    final s = context.read<SessionController>();
    if (s.isLoggedIn) {
      _fetchProfile();
    } else {
      setState(() {
        _profile = null;
        _err = null;
        _loading = false;
      });
    }
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final p = await context.read<IbooksRepository>().userProfile();
      if (!mounted) return;
      setState(() {
        _profile = p;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _err = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _AccountCard(
            session: session,
            profile: _profile,
            loading: _loading,
            err: _err,
            onLogin: () => context.push('/login'),
            onLogout: () async => session.logout(),
            onTopUp: () => context.push('/coinpurchase'),
            onConsumeLog: () => context.push('/consumelog'),
            onRetry: _fetchProfile,
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: InkWell(
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
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.workspace_premium, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('包月優惠套餐',
                            style: GoogleFonts.notoSansTc(
                                color: Colors.white, fontWeight: FontWeight.w700)),
                        Text('進入購買頁查看說明',
                            style: GoogleFonts.notoSansTc(
                                fontSize: 11, color: Colors.white70)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _MenuTile(icon: Icons.receipt_long_outlined, title: '我的訂單', onTap: () => context.push('/rechargeorders')),
        _MenuTile(icon: Icons.card_giftcard_outlined, title: '優惠券', trailing: '活動', onTap: () => context.push('/couponlist')),
        _MenuTile(icon: Icons.history, title: '瀏覽記錄', onTap: () => context.push('/browsehistory')),
        _MenuTile(icon: Icons.settings_outlined, title: '帳號與安全', onTap: () {}),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.session,
    required this.profile,
    required this.loading,
    required this.err,
    required this.onLogin,
    required this.onLogout,
    required this.onTopUp,
    required this.onConsumeLog,
    required this.onRetry,
  });

  final SessionController session;
  final UserProfile? profile;
  final bool loading;
  final String? err;
  final VoidCallback onLogin;
  final VoidCallback onLogout;
  final VoidCallback onTopUp;
  final VoidCallback onConsumeLog;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  session.isLoggedIn ? Icons.person : Icons.person_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.isLoggedIn
                          ? (profile?.nickname?.isNotEmpty == true
                              ? profile!.nickname!
                              : (session.nickname ??
                                  profile?.phone ??
                                  session.user?['phone']?.toString() ??
                                  '已登入'))
                          : '未登入',
                      style: GoogleFonts.notoSansTc(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.isLoggedIn
                          ? '手機：${profile?.phone ?? session.user?['phone'] ?? '-'}'
                          : '登入後可同步書架、購買章節',
                      style: GoogleFonts.notoSansTc(
                        fontSize: 11.5,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              if (session.isLoggedIn)
                TextButton(
                  onPressed: onLogout,
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  child: const Text('登出'),
                )
              else
                FilledButton(
                  onPressed: onLogin,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE566),
                    foregroundColor: IbColors.ink,
                  ),
                  child: Text('登入', style: GoogleFonts.notoSansTc(fontWeight: FontWeight.w700)),
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
            child: _balanceArea(),
          ),
          if (session.isLoggedIn) ...[
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
                    onPressed: onTopUp,
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
                    onPressed: onConsumeLog,
                    child: Text('消費記錄', style: GoogleFonts.notoSansTc(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _balanceArea() {
    if (!session.isLoggedIn) {
      return Text(
        '登入後在此顯示書幣餘額',
        style: GoogleFonts.notoSansTc(fontSize: 12, color: Colors.white70),
      );
    }
    if (loading && profile == null) {
      return const SizedBox(
        height: 28,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
          ),
        ),
      );
    }
    if (err != null && profile == null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              '加載餘額失敗：$err',
              style: GoogleFonts.notoSansTc(fontSize: 11.5, color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('重試'),
          ),
        ],
      );
    }
    final p = profile;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '帳戶餘額（書幣）',
                style: GoogleFonts.notoSansTc(fontSize: 10.5, color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    p == null ? '-' : _fmt(p.balance),
                    style: GoogleFonts.notoSansTc(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFFFE566),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('書幣',
                      style: GoogleFonts.notoSansTc(fontSize: 12, color: Colors.white)),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '已購章節',
              style: GoogleFonts.notoSansTc(fontSize: 10.5, color: Colors.white70),
            ),
            Text(
              '${p?.purchases ?? 0}',
              style: GoogleFonts.notoSansTc(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '書架收藏',
              style: GoogleFonts.notoSansTc(fontSize: 10.5, color: Colors.white70),
            ),
            Text(
              '${p?.shelfCount ?? 0}',
              style: GoogleFonts.notoSansTc(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _fmt(num n) {
    final i = n.toInt();
    return i.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.title, this.trailing, required this.onTap});

  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: const BoxDecoration(
        color: IbColors.bgCard,
        boxShadow: [BoxShadow(color: Color(0x141A1A1A), blurRadius: 8)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(icon, size: 18, color: IbColors.inkMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title, style: GoogleFonts.notoSansTc(fontSize: 13.5)),
                ),
                if (trailing != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(trailing!,
                        style: GoogleFonts.notoSansTc(fontSize: 11.5, color: IbColors.accent)),
                  ),
                Icon(Icons.chevron_right, color: IbColors.inkMuted.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

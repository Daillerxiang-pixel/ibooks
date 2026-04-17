import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../src/api/api_exception.dart';
import '../src/data/ibooks_repository.dart';
import '../src/data/session_controller.dart';
import '../theme/ibooks_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.redirectTo});

  /// 登入成功後導向（如 `/reader/1?bookId=2`）
  final String? redirectTo;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _nick = TextEditingController();
  bool _busy = false;
  String? _err;
  bool _registerMode = false;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _nick.dispose();
    super.dispose();
  }

  Future<void> _submit(Future<({String token, Map<String, dynamic> user})> Function() fn) async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      final r = await fn();
      if (!mounted) return;
      await context.read<SessionController>().setSession(r.token, r.user);
      if (!mounted) return;
      final red = widget.redirectTo;
      if (red != null && red.isNotEmpty) {
        context.go(red);
      } else {
        context.pop();
      }
    } catch (e) {
      setState(() {
        _err = e is ApiException ? e.message : e.toString();
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<IbooksRepository>();
    return Scaffold(
      backgroundColor: IbColors.bg,
      appBar: AppBar(
        backgroundColor: IbColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text('登入', style: GoogleFonts.notoSansTc(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '閱讀章節正文需登入（後端 JWT）。測試可註冊新帳號。',
            style: GoogleFonts.notoSansTc(fontSize: 12.5, color: IbColors.inkMuted, height: 1.5),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: '手機號'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: '密碼'),
          ),
          if (_registerMode) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _nick,
              decoration: const InputDecoration(labelText: '暱稱（可選）'),
            ),
          ],
          if (_err != null) ...[
            const SizedBox(height: 12),
            Text(_err!, style: GoogleFonts.notoSansTc(color: Colors.redAccent, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy
                ? null
                : () {
                    if (_registerMode) {
                      _submit(
                        () => repo.register(
                          phone: _phone.text.trim(),
                          password: _password.text,
                          nickname: _nick.text.trim().isEmpty ? null : _nick.text.trim(),
                        ),
                      );
                    } else {
                      _submit(() => repo.login(phone: _phone.text.trim(), password: _password.text));
                    }
                  },
            child: Text(_busy ? '請稍候…' : (_registerMode ? '註冊並登入' : '登入')),
          ),
          TextButton(
            onPressed: _busy ? null : () => setState(() => _registerMode = !_registerMode),
            child: Text(_registerMode ? '已有帳號？改為登入' : '沒有帳號？註冊'),
          ),
        ],
      ),
    );
  }
}

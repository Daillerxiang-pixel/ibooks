import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/ibooks_theme.dart';

class IbooksApp extends StatelessWidget {
  const IbooksApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'iBooks 繁體版',
      debugShowCheckedModeBanner: false,
      theme: IbTheme.light(),
      routerConfig: router,
    );
  }
}

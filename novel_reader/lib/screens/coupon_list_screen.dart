import 'package:flutter/material.dart';

import '../widgets/error_state.dart';
import '../widgets/ibooks_subpage_scaffold.dart';

class CouponListScreen extends StatelessWidget {
  const CouponListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const IbSubpageScaffold(
      title: '優惠券',
      subtitle: '餘額／面額 · 狀態',
      body: ApiUnavailableState(label: '優惠券'),
    );
  }
}

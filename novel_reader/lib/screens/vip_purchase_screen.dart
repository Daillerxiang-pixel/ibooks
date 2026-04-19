import 'package:flutter/material.dart';

import '../widgets/error_state.dart';
import '../widgets/ibooks_subpage_scaffold.dart';

class VipPurchaseScreen extends StatelessWidget {
  const VipPurchaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const IbSubpageScaffold(
      title: '會員購買',
      subtitle: '包月套餐 · 規則與支付',
      body: ApiUnavailableState(label: '包月套餐'),
    );
  }
}

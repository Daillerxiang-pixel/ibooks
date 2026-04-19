import 'package:flutter/material.dart';

import '../widgets/error_state.dart';
import '../widgets/ibooks_subpage_scaffold.dart';

class RechargeOrdersScreen extends StatelessWidget {
  const RechargeOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const IbSubpageScaffold(
      title: '充值訂單',
      subtitle: '我的儲值訂單',
      body: ApiUnavailableState(label: '充值訂單'),
    );
  }
}

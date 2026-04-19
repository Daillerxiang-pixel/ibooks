import 'package:flutter/material.dart';

import '../widgets/error_state.dart';
import '../widgets/ibooks_subpage_scaffold.dart';

class CoinPurchaseScreen extends StatelessWidget {
  const CoinPurchaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const IbSubpageScaffold(
      title: '書幣購買',
      subtitle: '儲值檔位 · 支付',
      body: ApiUnavailableState(label: '儲值檔位'),
    );
  }
}

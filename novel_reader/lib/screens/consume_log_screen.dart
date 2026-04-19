import 'package:flutter/material.dart';

import '../widgets/error_state.dart';
import '../widgets/ibooks_subpage_scaffold.dart';

class ConsumeLogScreen extends StatelessWidget {
  const ConsumeLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const IbSubpageScaffold(
      title: '消費記錄',
      subtitle: '書幣變動明細',
      body: ApiUnavailableState(label: '消費記錄'),
    );
  }
}

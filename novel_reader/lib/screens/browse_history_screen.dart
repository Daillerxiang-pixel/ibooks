import 'package:flutter/material.dart';

import '../widgets/error_state.dart';
import '../widgets/ibooks_subpage_scaffold.dart';

class BrowseHistoryScreen extends StatelessWidget {
  const BrowseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const IbSubpageScaffold(
      title: '瀏覽記錄',
      subtitle: '最近看過的書',
      body: ApiUnavailableState(label: '瀏覽記錄'),
    );
  }
}

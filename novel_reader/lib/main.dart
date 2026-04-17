import 'package:flutter/material.dart';

import 'app/ibooks_app.dart';
import 'router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(IbooksApp(router: AppRouter.create()));
}

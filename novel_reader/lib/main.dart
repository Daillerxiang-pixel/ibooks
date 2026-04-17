import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/ibooks_app.dart';
import 'config/app_config.dart';
import 'router/app_router.dart';
import 'src/api/ibooks_api_client.dart';
import 'src/data/ibooks_repository.dart';
import 'src/data/session_controller.dart';
import 'src/data/shelf_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = SessionController();
  await session.load();

  final api = IbooksApiClient(tokenGetter: () => session.token);
  final repo = IbooksRepository(api);
  final shelf = ShelfController(repository: repo, session: session);
  await shelf.bootstrap();

  debugPrint('iBooks API: ${AppConfig.apiBaseUrl}');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionController>.value(value: session),
        Provider<IbooksApiClient>.value(value: api),
        Provider<IbooksRepository>.value(value: repo),
        ChangeNotifierProvider<ShelfController>.value(value: shelf),
      ],
      child: IbooksApp(router: AppRouter.create()),
    ),
  );
}

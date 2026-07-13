import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'data/character_repository.dart';
import 'pages/home_page.dart';
import 'services/progress_store.dart';
import 'services/voice_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  final CharacterRepository repository = CharacterRepository();
  await repository.load();

  final ProgressStore progress = ProgressStore();
  await progress.load();

  runApp(WonderIslesApp(
    repository: repository,
    progress: progress,
  ));
}

class WonderIslesApp extends StatelessWidget {
  const WonderIslesApp({
    super.key,
    required this.repository,
    required this.progress,
  });

  final CharacterRepository repository;
  final ProgressStore progress;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<CharacterRepository>.value(value: repository),
        ChangeNotifierProvider<ProgressStore>.value(value: progress),
        Provider<VoiceService>(
          create: (_) => VoiceService(),
          dispose: (_, VoiceService v) => v.dispose(),
        ),
      ],
      child: MaterialApp(
        title: '奇思岛',
        debugShowCheckedModeBanner: false,
        theme: buildWonderIslesTheme(),
        home: const HomePage(),
      ),
    );
  }
}

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

  // 三个 load 之间只有 attachRepository 依赖 repository 就绪，其余互不依赖，
  // 并行加载可以显著缩短冷启动的白屏时间。
  final CharacterRepository repository = CharacterRepository();
  final ProgressStore progress = ProgressStore();
  final VoiceService voice = VoiceService();
  await Future.wait(<Future<void>>[
    repository.load(),
    progress.load(),
    voice.load(),
  ]);
  progress.attachRepository(repository);

  runApp(WonderIslesApp(
    repository: repository,
    progress: progress,
    voice: voice,
  ));
}

class WonderIslesApp extends StatelessWidget {
  const WonderIslesApp({
    super.key,
    required this.repository,
    required this.progress,
    required this.voice,
  });

  final CharacterRepository repository;
  final ProgressStore progress;
  final VoiceService voice;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<CharacterRepository>.value(value: repository),
        ChangeNotifierProvider<ProgressStore>.value(value: progress),
        ChangeNotifierProvider<VoiceService>.value(value: voice),
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
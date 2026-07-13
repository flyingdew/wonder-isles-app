import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'character.dart';

/// 从 assets/data/characters.json 加载字库并按 scene/order 分组。
class CharacterRepository {
  CharacterRepository();

  final Map<SceneId, List<WonderCharacter>> _bySceneCache =
      <SceneId, List<WonderCharacter>>{};
  List<WonderCharacter> _all = const <WonderCharacter>[];

  List<WonderCharacter> get all => _all;

  Future<void> load() async {
    final String raw = await rootBundle.loadString('assets/data/characters.json');
    final List<dynamic> list = json.decode(raw) as List<dynamic>;
    _all = list
        .map((dynamic e) =>
            WonderCharacter.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    _bySceneCache.clear();
    for (final SceneId scene in SceneId.values) {
      _bySceneCache[scene] = _all.where((WonderCharacter c) => c.scene == scene).toList()
        ..sort((WonderCharacter a, WonderCharacter b) => a.order.compareTo(b.order));
    }
  }

  List<WonderCharacter> forScene(SceneId scene) =>
      _bySceneCache[scene] ?? const <WonderCharacter>[];

  WonderCharacter byId(String id) =>
      _all.firstWhere((WonderCharacter c) => c.id == id);
}

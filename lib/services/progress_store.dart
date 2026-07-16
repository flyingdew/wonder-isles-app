import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地存档：记录点亮过的字 id、以及每个字的复访次数。
/// v2 起额外记录已完成的场景小诗 id 集合。
class ProgressStore extends ChangeNotifier {
  static const String _kLit = 'wonder_isles.lit';
  static const String _kVisitPrefix = 'wonder_isles.visit.';
  static const String _kPoems = 'wonder_isles.poems';

  final Set<String> _lit = <String>{};
  final Map<String, int> _visits = <String, int>{};
  final Set<String> _poems = <String>{};
  SharedPreferences? _prefs;

  Set<String> get litIds => Set<String>.unmodifiable(_lit);
  int get litCount => _lit.length;
  Set<String> get completedPoems => Set<String>.unmodifiable(_poems);

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _lit
      ..clear()
      ..addAll(_prefs?.getStringList(_kLit) ?? <String>[]);
    _poems
      ..clear()
      ..addAll(_prefs?.getStringList(_kPoems) ?? <String>[]);
    _visits.clear();
    for (final String key in _prefs?.getKeys() ?? const <String>{}) {
      if (key.startsWith(_kVisitPrefix)) {
        _visits[key.substring(_kVisitPrefix.length)] =
            _prefs?.getInt(key) ?? 0;
      }
    }
  }

  bool isLit(String id) => _lit.contains(id);
  int visits(String id) => _visits[id] ?? 0;
  bool isPoemDone(String sceneKey) => _poems.contains(sceneKey);

  Future<void> markLit(String id) async {
    _visits[id] = (_visits[id] ?? 0) + 1;
    await _prefs?.setInt('$_kVisitPrefix$id', _visits[id]!);
    if (_lit.add(id)) {
      await _prefs?.setStringList(_kLit, _lit.toList());
    }
    notifyListeners();
  }

  Future<void> markPoemDone(String sceneKey) async {
    if (_poems.add(sceneKey)) {
      await _prefs?.setStringList(_kPoems, _poems.toList());
      notifyListeners();
    }
  }

  Future<void> reset() async {
    _lit.clear();
    _visits.clear();
    _poems.clear();
    await _prefs?.clear();
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地存档：记录点亮过的字 id、以及每个字的复访次数。
class ProgressStore extends ChangeNotifier {
  static const String _kLit = 'wonder_isles.lit';
  static const String _kVisitPrefix = 'wonder_isles.visit.';

  final Set<String> _lit = <String>{};
  final Map<String, int> _visits = <String, int>{};
  SharedPreferences? _prefs;

  Set<String> get litIds => Set<String>.unmodifiable(_lit);
  int get litCount => _lit.length;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _lit
      ..clear()
      ..addAll(_prefs?.getStringList(_kLit) ?? <String>[]);
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

  Future<void> markLit(String id) async {
    _visits[id] = (_visits[id] ?? 0) + 1;
    await _prefs?.setInt('$_kVisitPrefix$id', _visits[id]!);
    if (_lit.add(id)) {
      await _prefs?.setStringList(_kLit, _lit.toList());
    }
    notifyListeners();
  }

  Future<void> reset() async {
    _lit.clear();
    _visits.clear();
    await _prefs?.clear();
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/achievement.dart';
import '../data/character.dart';
import '../data/character_repository.dart';
import '../data/number_repository.dart';

/// 本地存档：记录点亮过的字 id、每字复访次数、已完成场景诗、成就与连续访问天数。
class ProgressStore extends ChangeNotifier {
  static const String _kLit = 'wonder_isles.lit';
  static const String _kVisitPrefix = 'wonder_isles.visit.';
  static const String _kPoems = 'wonder_isles.poems';
  static const String _kAchievements = 'wonder_isles.achievements';
  static const String _kLastVisit = 'wonder_isles.streak.lastVisit';
  static const String _kStreak = 'wonder_isles.streak.count';
  // ---- 数之岛（第二章） ----
  static const String _kNumLit = 'wonder_isles.numbers.lit';
  static const String _kNumVisitPrefix = 'wonder_isles.numbers.visit.';
  static const String _kNumMathDone = 'wonder_isles.numbers.math_done';

  final Set<String> _lit = <String>{};
  final Map<String, int> _visits = <String, int>{};
  final Set<String> _poems = <String>{};
  final Set<String> _achievements = <String>{};
  SharedPreferences? _prefs;
  CharacterRepository? _repo;
  NumberRepository? _numRepo;
  DateTime? _lastVisit;
  int _streak = 0;
  final Set<String> _numLit = <String>{};
  final Map<String, int> _numVisits = <String, int>{};
  bool _numMathDone = false;

  Set<String> get litIds => Set<String>.unmodifiable(_lit);
  int get litCount => _lit.length;
  Set<String> get completedPoems => Set<String>.unmodifiable(_poems);
  Set<String> get unlockedAchievements =>
      Set<String>.unmodifiable(_achievements);
  int get streakDays => _streak;
  Set<String> get numberLitIds => Set<String>.unmodifiable(_numLit);
  int get numberLitCount => _numLit.length;
  Map<String, int> get allNumberVisits =>
      Map<String, int>.unmodifiable(_numVisits);
  bool get isNumberMathDone => _numMathDone;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _lit
      ..clear()
      ..addAll(_prefs?.getStringList(_kLit) ?? <String>[]);
    _poems
      ..clear()
      ..addAll(_prefs?.getStringList(_kPoems) ?? <String>[]);
    _achievements
      ..clear()
      ..addAll(_prefs?.getStringList(_kAchievements) ?? <String>[]);
    _visits.clear();
    _numLit
      ..clear()
      ..addAll(_prefs?.getStringList(_kNumLit) ?? <String>[]);
    _numVisits.clear();
    _numMathDone = _prefs?.getBool(_kNumMathDone) ?? false;
    for (final String key in _prefs?.getKeys() ?? const <String>{}) {
      if (key.startsWith(_kVisitPrefix)) {
        _visits[key.substring(_kVisitPrefix.length)] =
            _prefs?.getInt(key) ?? 0;
      } else if (key.startsWith(_kNumVisitPrefix)) {
        _numVisits[key.substring(_kNumVisitPrefix.length)] =
            _prefs?.getInt(key) ?? 0;
      }
    }
    final String? lastRaw = _prefs?.getString(_kLastVisit);
    _lastVisit = lastRaw == null ? null : DateTime.tryParse(lastRaw);
    _streak = _prefs?.getInt(_kStreak) ?? 0;
  }

  /// 由 main() 在字库加载完后注入，成就评估需要按场景/整章计数。
  void attachRepository(CharacterRepository repo) {
    _repo = repo;
  }

  /// 由 main() 在数之岛字库加载完后注入，用于评估 numbers_all 成就。
  void attachNumberRepository(NumberRepository repo) {
    _numRepo = repo;
  }

  bool isLit(String id) => _lit.contains(id);
  bool isNumberLit(String id) => _numLit.contains(id);
  int numberVisits(String id) => _numVisits[id] ?? 0;
  int visits(String id) => _visits[id] ?? 0;
  Map<String, int> get allVisits => Map<String, int>.unmodifiable(_visits);
  bool isPoemDone(String sceneKey) => _poems.contains(sceneKey);
  bool hasAchievement(String id) => _achievements.contains(id);

  Future<List<Achievement>> markLit(String id) async {
    _visits[id] = (_visits[id] ?? 0) + 1;
    await _prefs?.setInt('$_kVisitPrefix$id', _visits[id]!);
    if (_lit.add(id)) {
      await _prefs?.setStringList(_kLit, _lit.toList());
    }
    notifyListeners();
    return _evaluate();
  }

  Future<List<Achievement>> markNumberLit(String id) async {
    _numVisits[id] = (_numVisits[id] ?? 0) + 1;
    await _prefs?.setInt('$_kNumVisitPrefix$id', _numVisits[id]!);
    if (_numLit.add(id)) {
      await _prefs?.setStringList(_kNumLit, _numLit.toList());
    }
    notifyListeners();
    return _evaluate();
  }
  Future<List<Achievement>> markNumberMathDone() async {
    if (!_numMathDone) {
      _numMathDone = true;
      await _prefs?.setBool(_kNumMathDone, true);
      notifyListeners();
    }
    return _evaluate();
  }

  Future<List<Achievement>> markPoemDone(String sceneKey) async {
    if (_poems.add(sceneKey)) {
      await _prefs?.setStringList(_kPoems, _poems.toList());
      notifyListeners();
    }
    return _evaluate();
  }

  /// 应用入口调用一次，按今天日期滚动 streak，并可能解锁"三日结伴"。
  Future<List<Achievement>> recordDailyVisit() async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime? last = _lastVisit == null
        ? null
        : DateTime(_lastVisit!.year, _lastVisit!.month, _lastVisit!.day);

    if (last == null) {
      _streak = 1;
    } else {
      final int diff = today.difference(last).inDays;
      if (diff == 0) {
        // 同一天再次进入，不变。
      } else if (diff == 1) {
        _streak += 1;
      } else {
        _streak = 1;
      }
    }
    _lastVisit = today;
    await _prefs?.setString(_kLastVisit, today.toIso8601String());
    await _prefs?.setInt(_kStreak, _streak);
    notifyListeners();
    return _evaluate();
  }

  Future<List<Achievement>> _evaluate() async {
    final List<Achievement> newly = <Achievement>[];

    void tryUnlock(String id) {
      if (_achievements.contains(id)) return;
      newly.add(achievementById(id));
      _achievements.add(id);
    }

    if (_lit.isNotEmpty) tryUnlock('first_lit');
    if (_repo != null) {
      for (final SceneId scene in SceneId.values) {
        final Set<String> ids =
            _repo!.forScene(scene).map((c) => c.id).toSet();
        if (ids.isNotEmpty && ids.every(_lit.contains)) {
          tryUnlock('scene_complete');
          break;
        }
      }
      final Set<String> all = _repo!.all.map((c) => c.id).toSet();
      if (all.isNotEmpty && all.every(_lit.contains)) {
        tryUnlock('all_lit');
      }
    }
    if (_poems.contains('boss')) tryUnlock('poem_boss');
    if (_streak >= 3) tryUnlock('streak_3');

    if (_numLit.isNotEmpty) tryUnlock('numbers_first');
    if (_numRepo != null) {
      final Set<String> all = _numRepo!.all.map((e) => e.id).toSet();
      if (all.isNotEmpty && all.every(_numLit.contains)) {
        tryUnlock('numbers_all');
      }
    }
    if (_poems.contains('numbers_isle')) tryUnlock('numbers_rhyme');
    if (_numMathDone) tryUnlock('numbers_math');

    if (newly.isNotEmpty) {
      await _prefs?.setStringList(_kAchievements, _achievements.toList());
      notifyListeners();
    }
    return newly;
  }

  Future<void> reset() async {
    _lit.clear();
    _visits.clear();
    _numLit.clear();
    _numVisits.clear();
    _numMathDone = false;
    _poems.clear();
    _achievements.clear();
    _lastVisit = null;
    _streak = 0;
    await _prefs?.clear();
    notifyListeners();
  }
}
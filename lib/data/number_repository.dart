import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'number_entry.dart';

/// 从 assets/data/numbers.json 加载数之岛字库。
class NumberRepository {
  NumberRepository();

  List<NumberEntry> _all = const <NumberEntry>[];

  List<NumberEntry> get all => _all;

  Future<void> load() async {
    final String raw =
        await rootBundle.loadString('assets/data/numbers.json');
    final List<dynamic> list = json.decode(raw) as List<dynamic>;
    _all = list
        .map((dynamic e) =>
            NumberEntry.fromJson(e as Map<String, dynamic>))
        .toList(growable: false)
      ..sort((NumberEntry a, NumberEntry b) => a.day.compareTo(b.day));
  }

  NumberEntry byId(String id) =>
      _all.firstWhere((NumberEntry e) => e.id == id);
}
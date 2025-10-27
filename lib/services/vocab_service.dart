import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/vocab.dart';

class VocabService {
  Future<List<Vocab>> loadFromAssets(String assetPath) async {
    try {
      final s = await rootBundle.loadString(assetPath);
      final arr = json.decode(s) as List<dynamic>;
      return arr.map((e) => Vocab.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  List<Vocab> merge(List<Vocab> base, List<Vocab> user) {
    final map = <String, Vocab>{};
    for (final v in base) map[v.id] = v;
    for (final v in user) map[v.id] = v;
    return map.values.toList();
  }
}

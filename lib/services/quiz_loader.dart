import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/quiz_models.dart';

class QuizLoader {
  Future<QuizPack> loadFromAsset(String assetPath) async {
    final s = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> j = json.decode(s) as Map<String, dynamic>;
    return QuizPack.fromJson(j);
  }

  Future<QuizPack?> tryLoadFromAsset(String assetPath) async {
    try {
      return await loadFromAsset(assetPath);
    } catch (_) {
      return null;
    }
  }
}

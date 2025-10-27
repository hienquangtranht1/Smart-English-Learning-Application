import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_models.dart';

class QuizStorageService {
  static const _prefsPrefix = 'quiz_pack_';

  String _prefsKeyFor(String assetPath) {
    final name = assetPath.split('/').where((p) => p.isNotEmpty).last;
    return '$_prefsPrefix$name';
  }

  Future<QuizPack> loadPack(String assetPath, {QuizPack? defaultPack}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _prefsKeyFor(assetPath);
    final s = prefs.getString(key);
    if (s != null && s.isNotEmpty) {
      try {
        if (kDebugMode) debugPrint('QuizStorageService.loadPack: load from prefs key=$key len=${s.length}');
        final Map<String, dynamic> j = json.decode(s) as Map<String, dynamic>;
        return QuizPack.fromJson(j);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('QuizStorageService.loadPack: parse error for key=$key: $e');
          debugPrint('$st');
        }
      }
    }

    if (defaultPack != null) {
      if (kDebugMode) debugPrint('QuizStorageService.loadPack: returning provided defaultPack');
      return defaultPack;
    }

    try {
      final sAsset = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> jAsset = json.decode(sAsset) as Map<String, dynamic>;
      if (kDebugMode) debugPrint('QuizStorageService.loadPack: loaded from asset $assetPath');
      return QuizPack.fromJson(jAsset);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('QuizStorageService.loadPack: failed to load asset $assetPath: $e');
        debugPrint('$st');
      }
      return QuizPack(title: 'Untitled', language: 'vi', level: '', exercises: []);
    }
  }

  Future<void> savePack(String assetPath, QuizPack pack) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _prefsKeyFor(assetPath);
    final j = json.encode(pack.toJson());
    try {
      final ok = await prefs.setString(key, j);
      if (!ok) throw Exception('SharedPreferences.setString returned false for key=$key');
      if (kDebugMode) debugPrint('QuizStorageService.savePack: wrote key=$key len=${j.length}');
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('QuizStorageService.savePack ERROR for key=$key : $e');
        debugPrint('$st');
      }
      rethrow;
    }
  }

  Future<void> addExercise(String assetPath, Exercise ex, {QuizPack? defaultPack}) async {
    try {
      final pack = await loadPack(assetPath, defaultPack: defaultPack);
      final maxId = pack.exercises.fold<int>(0, (p, e) => e.id > p ? e.id : p);
      ex.id = maxId + 1;
      pack.exercises.add(ex);
      await savePack(assetPath, pack);
      if (kDebugMode) debugPrint('QuizStorageService.addExercise: added id=${ex.id} key=${_prefsKeyFor(assetPath)}');
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('QuizStorageService.addExercise ERROR: $e');
        debugPrint('$st');
      }
      rethrow;
    }
  }

  Future<void> editExercise(String assetPath, Exercise ex, {QuizPack? defaultPack}) async {
    try {
      final pack = await loadPack(assetPath, defaultPack: defaultPack);
      final idx = pack.exercises.indexWhere((e) => e.id == ex.id);
      if (idx >= 0) {
        pack.exercises[idx] = ex;
        await savePack(assetPath, pack);
        if (kDebugMode) debugPrint('QuizStorageService.editExercise: saved id=${ex.id}');
      } else {
        throw Exception('Exercise not found id=${ex.id}');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('QuizStorageService.editExercise ERROR: $e');
        debugPrint('$st');
      }
      rethrow;
    }
  }

  Future<void> deleteExercise(String assetPath, int exerciseId, {QuizPack? defaultPack}) async {
    try {
      final pack = await loadPack(assetPath, defaultPack: defaultPack);
      final before = pack.exercises.length;
      pack.exercises.removeWhere((e) => e.id == exerciseId);
      final after = pack.exercises.length;
      await savePack(assetPath, pack);
      if (kDebugMode) debugPrint('QuizStorageService.deleteExercise: id=$exerciseId before=$before after=$after');
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('QuizStorageService.deleteExercise ERROR: $e');
        debugPrint('$st');
      }
      rethrow;
    }
  }
  Future<void> deleteUserPack(String assetPath) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _prefsKeyFor(assetPath);
    if (prefs.containsKey(key)) {
      final ok = await prefs.remove(key);
      if (!ok) throw Exception('SharedPreferences.remove returned false for key=$key');
      if (kDebugMode) debugPrint('QuizStorageService.deleteUserPack: removed key=$key');
    } else {
      if (kDebugMode) debugPrint('QuizStorageService.deleteUserPack: key not found=$key');
    }
  }

  Future<List<String>> debugListKeys() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys().toList();
  }

  Future<String?> debugReadKey(String assetPath) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _prefsKeyFor(assetPath);
    return prefs.getString(key);
  }
}

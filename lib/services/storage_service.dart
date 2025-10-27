import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vocab.dart';
import '../models/quiz_result.dart';

class StorageService {
  static const String _userVocabKey = 'user_vocab_v1';
  static const String _deletedIdsKey = 'deleted_vocab_ids_v1';
  static const String _favoritesKeyPrefix = 'favorites_';
  static const String _favoritesGuestKey = 'favorites_guest_v1';
  static const String _historyPrefix = 'quiz_history_';
  static const String _guestHistoryKey = 'quiz_history_guest_v1';

  Future<SharedPreferences> _prefs() async => await SharedPreferences.getInstance();


  Future<List<Vocab>> loadUserVocab() async {
    final prefs = await _prefs();
    final s = prefs.getString(_userVocabKey);
    if (s == null || s.isEmpty) return [];
    try {
      final List<dynamic> arr = json.decode(s) as List<dynamic>;
      return arr.map((e) => Vocab.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveUserVocab(List<Vocab> list) async {
    final prefs = await _prefs();
    await prefs.setString(_userVocabKey, json.encode(list.map((e) => e.toJson()).toList()));
  }

  Future<List<String>> loadDeletedIds() async {
    final prefs = await _prefs();
    final s = prefs.getString(_deletedIdsKey);
    if (s == null || s.isEmpty) return [];
    try {
      final List<dynamic> arr = json.decode(s) as List<dynamic>;
      return arr.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveDeletedIds(List<String> ids) async {
    final prefs = await _prefs();
    await prefs.setString(_deletedIdsKey, json.encode(ids));
  }


  String _favoritesKeyFor(String? username) {
    if (username == null || username.trim().isEmpty) return _favoritesGuestKey;
    return '$_favoritesKeyPrefix${username.trim().toLowerCase()}';
  }

  Future<List<String>> loadFavorites({String? username}) async {
    final prefs = await _prefs();
    final key = _favoritesKeyFor(username);
    final s = prefs.getString(key);
    if (s == null || s.isEmpty) return [];
    try {
      final List<dynamic> arr = json.decode(s) as List<dynamic>;
      return arr.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveFavorites(List<String> ids, {String? username}) async {
    final prefs = await _prefs();
    final key = _favoritesKeyFor(username);
    await prefs.setString(key, json.encode(ids));
  }

  String _historyKeyFor(String? username) {
    if (username == null || username.trim().isEmpty) return _guestHistoryKey;
    return '$_historyPrefix${username.trim().toLowerCase()}';
  }

  Future<void> appendQuizHistory(QuizResult result, {String? username}) async {
    final prefs = await _prefs();
    final key = _historyKeyFor(username);
    final raw = prefs.getString(key);
    List<dynamic> arr = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        arr = json.decode(raw) as List<dynamic>;
      } catch (_) {
        arr = [];
      }
    }
    arr.add(result.toJson());
    await prefs.setString(key, json.encode(arr));
  }

  Future<List<QuizResult>> loadQuizHistory({String? username}) async {
    final prefs = await _prefs();
    final key = _historyKeyFor(username);
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return <QuizResult>[];
    try {
      final List<dynamic> arr = json.decode(raw) as List<dynamic>;
      return arr.map((e) => QuizResult.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return <QuizResult>[];
    }
  }

  Future<void> clearQuizHistory({String? username}) async {
    final prefs = await _prefs();
    final key = _historyKeyFor(username);
    await prefs.remove(key);
  }
}

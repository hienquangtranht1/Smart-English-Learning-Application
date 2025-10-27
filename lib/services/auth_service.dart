import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';
import 'email_service.dart';

class AuthService extends ChangeNotifier {
  static const _keySession = 'auth_session_v1';
  static const _keyUsers = 'auth_users_v1';


  static const _otpKeyPrefix = 'otp_';
  static const _otpTimePrefix = 'otp_time_';
  static const _otpPassPrefix = 'otp_pass_';
  static const _otpEmailPrefix = 'otp_email_';

  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  User? _currentUser;
  bool _initialized = false;

  AuthService() {
    _loadFromPrefs();
  }

  bool get isInitialized => _initialized;
  User? get currentUser => _currentUser;
  String? get currentUsername => _currentUser?.username;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin == true;


  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_keySession);
    if (s != null && s.isNotEmpty) {
      try {
        final Map<String, dynamic> j = json.decode(s) as Map<String, dynamic>;
        _currentUser = User.fromJson(Map<String, dynamic>.from(j));
      } catch (_) {
        _currentUser = null;
      }
    }

    final usersRaw = prefs.getString(_keyUsers);
    if (usersRaw == null || usersRaw.isEmpty) {
      final defaultUsers = [
        {'username': 'admin', 'password': 'admin', 'isAdmin': true, 'email': ''},
        {'username': 'user', 'password': 'user', 'isAdmin': false, 'email': ''},
      ];
      await prefs.setString(_keyUsers, json.encode(defaultUsers));
    }

    _initialized = true;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> _loadUsersRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_keyUsers);
    if (s == null || s.isEmpty) return [];
    try {
      final List<dynamic> arr = json.decode(s) as List<dynamic>;
      return arr.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveUsersRaw(List<Map<String, dynamic>> arr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsers, json.encode(arr));
  }

  Future<void> _saveSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySession, json.encode(user.toJson()));
  }

  String _normalizeId(String s) => s.trim().toLowerCase();


  Future<bool> login(String username, String password) async {
    username = username.trim();
    final users = await _loadUsersRaw();
    final found = users.firstWhere(
          (u) =>
      (u['username'] as String).toLowerCase() == username.toLowerCase() &&
          (u['password'] as String) == password,
      orElse: () => <String, dynamic>{},
    );

    if (found.isEmpty) return false;

    final user = User(
      username: found['username'] as String,
      isAdmin: found['isAdmin'] == true,
      email: (found['email'] as String?) ?? '',
    );

    _currentUser = user;
    await _saveSession(user);
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySession);
    notifyListeners();
  }

  Future<bool> register(String username, String password, {required String email, bool makeAdmin = false}) async {
    username = username.trim();
    final normUsername = _normalizeId(username);
    final normEmail = email.trim().toLowerCase();

    if (normUsername.isEmpty || password.isEmpty || normEmail.isEmpty) return false;

    final users = await _loadUsersRaw();

    final existsUsername = users.any((u) => (u['username'] as String).toLowerCase() == normUsername);
    if (existsUsername) return false;

    final existsEmail = users.any((u) {
      final e = (u['email'] as String?) ?? '';
      return e.isNotEmpty && e.toLowerCase() == normEmail;
    });
    if (existsEmail) return false;

    users.add({
      'username': username,
      'password': password,
      'isAdmin': makeAdmin,
      'email': normEmail,
    });

    await _saveUsersRaw(users);
    return true;
  }

  Future<List<User>> listUsers() async {
    final users = await _loadUsersRaw();
    return users
        .map((u) => User(
      username: u['username'] as String,
      isAdmin: u['isAdmin'] == true,
      email: (u['email'] as String?) ?? '',
    ))
        .toList();
  }

  Future<bool> removeUser(String username) async {
    final users = await _loadUsersRaw();
    final targetIndex = users.indexWhere((u) => (u['username'] as String).toLowerCase() == username.toLowerCase());
    if (targetIndex < 0) return false;

    final isTargetAdmin = users[targetIndex]['isAdmin'] == true;
    if (isTargetAdmin) {
      final otherAdmins = users.where((u) => u['isAdmin'] == true && (u['username'] as String).toLowerCase() != username.toLowerCase()).toList();
      if (otherAdmins.isEmpty) return false;
    }

    users.removeAt(targetIndex);
    await _saveUsersRaw(users);

    if (_currentUser != null && _currentUser!.username.toLowerCase() == username.toLowerCase()) {
      await logout();
    }

    notifyListeners();
    return true;
  }

  Future<bool> toggleAdmin(String username) async {
    final users = await _loadUsersRaw();
    final idx = users.indexWhere((u) => (u['username'] as String).toLowerCase() == username.toLowerCase());
    if (idx < 0) return false;

    final current = users[idx];
    final bool newIsAdmin = !(current['isAdmin'] == true);

    if (!newIsAdmin) {
      final adminCount = users.where((u) => u['isAdmin'] == true).length;
      if (adminCount <= 1) return false;
    }

    users[idx]['isAdmin'] = newIsAdmin;
    await _saveUsersRaw(users);

    if (_currentUser != null && _currentUser!.username.toLowerCase() == username.toLowerCase()) {
      _currentUser = User(username: _currentUser!.username, isAdmin: newIsAdmin, email: _currentUser!.email);
      await _saveSession(_currentUser!);
    }

    notifyListeners();
    return true;
  }

  Future<bool> resetPassword(String username, String newPassword) async {
    final users = await _loadUsersRaw();
    final idx = users.indexWhere((u) => (u['username'] as String).toLowerCase() == username.toLowerCase());
    if (idx < 0) return false;
    users[idx]['password'] = newPassword;
    await _saveUsersRaw(users);

    if (_currentUser != null && _currentUser!.username.toLowerCase() == username.toLowerCase()) {
      _currentUser = User(username: _currentUser!.username, isAdmin: _currentUser!.isAdmin, email: _currentUser!.email);
      await _saveSession(_currentUser!);
      notifyListeners();
    }

    return true;
  }


  String _generateOtp() {
    final rnd = Random.secure();
    final code = rnd.nextInt(900000) + 100000;
    return code.toString();
  }

  Future<void> _storeOtp(String id, String otp, {String? password, String? email}) async {
    final now = DateTime.now().toIso8601String();
    final norm = _normalizeId(id);
    await _secure.write(key: '$_otpKeyPrefix$norm', value: otp);
    await _secure.write(key: '$_otpTimePrefix$norm', value: now);
    if (password != null) await _secure.write(key: '$_otpPassPrefix$norm', value: password);
    if (email != null) await _secure.write(key: '$_otpEmailPrefix$norm', value: email);
    if (kDebugMode) debugPrint('AuthService: stored OTP for $norm otp=$otp');
  }

  Future<void> _clearOtp(String id) async {
    final norm = _normalizeId(id);
    await _secure.delete(key: '$_otpKeyPrefix$norm');
    await _secure.delete(key: '$_otpTimePrefix$norm');
    await _secure.delete(key: '$_otpPassPrefix$norm');
    await _secure.delete(key: '$_otpEmailPrefix$norm');
    if (kDebugMode) debugPrint('AuthService: cleared OTP for $norm');
  }

  Future<Map<String, String>?> getStoredRegisterTemp(String username) async {
    final id = _normalizeId(username);
    final otp = await _secure.read(key: '$_otpKeyPrefix$id');
    final time = await _secure.read(key: '$_otpTimePrefix$id');
    final pass = await _secure.read(key: '$_otpPassPrefix$id');
    final email = await _secure.read(key: '$_otpEmailPrefix$id');
    if (otp == null && pass == null && email == null && time == null) return null;
    return {
      'otp': otp ?? '',
      'time': time ?? '',
      'password': pass ?? '',
      'email': email ?? '',
    };
  }

  Future<bool> requestRegisterOtp({
    required String username,
    required String password,
    required String email,
    required EmailService emailService,
    int otpTtlMinutes = 5,
  }) async {
    final id = _normalizeId(username);
    final normEmail = email.trim().toLowerCase();
    if (id.isEmpty || password.isEmpty || normEmail.isEmpty) return false;

    final users = await _loadUsersRaw();
    final existsUsername = users.any((u) => (u['username'] as String).toLowerCase() == id);
    if (existsUsername) return false;

    final existsEmail = users.any((u) {
      final e = (u['email'] as String?) ?? '';
      return e.isNotEmpty && e.toLowerCase() == normEmail;
    });
    if (existsEmail) return false;

    final otp = _generateOtp();
    final subject = 'OTP xác nhận đăng ký';
    final body = 'Xin chào $username,\nMã OTP đăng ký của bạn: $otp\nMã có hiệu lực $otpTtlMinutes phút.';

    final sent = await emailService.sendEmail(toEmail: normEmail, subject: subject, body: body);
    if (!sent) return false;

    await _storeOtp(id, otp, password: password, email: normEmail);
    return true;
  }

  Future<bool> confirmRegisterOtp({
    required String username,
    required String otp,
    bool makeAdmin = false,
    int otpTtlMinutes = 5,
  }) async {
    final id = _normalizeId(username);
    final storedOtp = await _secure.read(key: '$_otpKeyPrefix$id');
    final storedTime = await _secure.read(key: '$_otpTimePrefix$id');
    final storedPass = await _secure.read(key: '$_otpPassPrefix$id');
    final storedEmail = await _secure.read(key: '$_otpEmailPrefix$id');

    if (storedOtp == null || storedTime == null || storedPass == null || storedEmail == null) return false;

    final created = DateTime.tryParse(storedTime);
    if (created == null) {
      await _clearOtp(id);
      return false;
    }

    if (DateTime.now().difference(created) > Duration(minutes: otpTtlMinutes)) {
      await _clearOtp(id);
      return false;
    }

    if (otp.trim() != storedOtp.trim()) return false;

    final users = await _loadUsersRaw();
    final normEmail = storedEmail.trim().toLowerCase();

    final existsUsername = users.any((u) => (u['username'] as String).toLowerCase() == id);
    if (existsUsername) {
      await _clearOtp(id);
      return false;
    }

    final existsEmail = users.any((u) {
      final e = (u['email'] as String?) ?? '';
      return e.isNotEmpty && e.toLowerCase() == normEmail;
    });
    if (existsEmail) {
      await _clearOtp(id);
      return false;
    }

    final registered = await register(id, storedPass, email: normEmail, makeAdmin: makeAdmin);
    await _clearOtp(id);
    return registered;
  }

  Future<bool> requestResetOtp({
    required String usernameOrEmail,
    required EmailService emailService,
    int otpTtlMinutes = 5,
  }) async {
    final identifier = usernameOrEmail.trim();
    if (identifier.isEmpty) return false;

    final users = await _loadUsersRaw();
    String? foundUsername;
    String? foundEmail;

    for (final u in users) {
      final uname = (u['username'] as String);
      if (uname.toLowerCase() == identifier.toLowerCase()) {
        foundUsername = uname;
        foundEmail = (u['email'] as String?) ?? '';
        break;
      }

      final emailField = (u['email'] as String?) ?? '';
      if (emailField.isNotEmpty && emailField.toLowerCase() == identifier.toLowerCase()) {
        foundUsername = u['username'] as String;
        foundEmail = emailField;
        break;
      }
    }

    if (foundUsername == null) return false;
    if (foundEmail == null || foundEmail.isEmpty) return false;

    final otp = _generateOtp();
    final subject = 'OTP đổi mật khẩu';
    final body = 'Mã OTP đổi mật khẩu của bạn: $otp\nMã có hiệu lực $otpTtlMinutes phút.';

    final sent = await emailService.sendEmail(toEmail: foundEmail, subject: subject, body: body);
    if (!sent) return false;

    await _storeOtp(foundUsername.toLowerCase(), otp, email: foundEmail);
    return true;
  }

  Future<bool> confirmResetOtp({
    required String username,
    required String otp,
    required String newPassword,
    int otpTtlMinutes = 5,
  }) async {
    final id = _normalizeId(username);
    final storedOtp = await _secure.read(key: '$_otpKeyPrefix$id');
    final storedTime = await _secure.read(key: '$_otpTimePrefix$id');

    if (storedOtp == null || storedTime == null) return false;

    final created = DateTime.tryParse(storedTime);
    if (created == null) {
      await _clearOtp(id);
      return false;
    }

    if (DateTime.now().difference(created) > Duration(minutes: otpTtlMinutes)) {
      await _clearOtp(id);
      return false;
    }

    if (otp.trim() != storedOtp.trim()) return false;

    final ok = await resetPassword(id, newPassword);
    await _clearOtp(id);
    return ok;
  }
}

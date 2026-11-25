import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../local/daos/user_dao.dart';
import '../local/daos/session_dao.dart';
import '../models/user.dart';

class AuthRepository {
  final UserDao _userDao;
  final SessionDao _sessionDao;
  User? _currentUser;

  AuthRepository({UserDao? userDao, SessionDao? sessionDao})
      : _userDao = userDao ?? UserDao(),
        _sessionDao = sessionDao ?? SessionDao();

  String _hashPassword(String password, {String salt = 'an_lanh_salt_v1'}) {
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }

  Future<bool> register(String email, String password, String name) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();
    if (cleanEmail.isEmpty || password.isEmpty || cleanName.isEmpty) {
      return false;
    }

    final existingEmail = await _userDao.getUserByEmail(cleanEmail);
    if (existingEmail != null) {
      return false;
    }

    final existingUser = await _userDao.getUserByUsername(cleanName);
    if (existingUser != null) {
      return false;
    }

    final passwordHash = _hashPassword(password);
    final now = DateTime.now().toIso8601String();

    final user = User(
      username: cleanName,
      email: cleanEmail,
      passwordHash: passwordHash,
      createdAt: now,
    );

    try {
      final id = await _userDao.insertUser(user.toMap());
      if (id > 0) {
        _currentUser = user.copyWith(id: id);
        await _sessionDao.setCurrentUserId(id);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<User?> login(String email, String password) async {
    final cleanIdentifier = email.trim();
    if (cleanIdentifier.isEmpty || password.isEmpty) {
      return null;
    }

    final passwordHash = _hashPassword(password);
    final userMap = await _userDao.verifyUser(cleanIdentifier, passwordHash);
    if (userMap != null) {
      _currentUser = User.fromMap(userMap);
      if (_currentUser?.id != null) {
        await _sessionDao.setCurrentUserId(_currentUser!.id);
      }
      return _currentUser;
    }
    return null;
  }

  Future<User?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    final sessionUserId = await _sessionDao.getCurrentUserId();
    if (sessionUserId != null) {
      final userMap = await _userDao.getUserById(sessionUserId);
      if (userMap != null) {
        _currentUser = User.fromMap(userMap);
        return _currentUser;
      }
    }
    return null;
  }

  Future<void> logout() async {
    _currentUser = null;
    await _sessionDao.setCurrentUserId(null);
  }
}

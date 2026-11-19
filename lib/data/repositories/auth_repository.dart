import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../local/daos/user_dao.dart';
import '../models/user.dart';

class AuthRepository {
  final UserDao _userDao;
  User? _currentUser;

  AuthRepository({UserDao? userDao}) : _userDao = userDao ?? UserDao();

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
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
      return _currentUser;
    }
    return null;
  }

  Future<User?> getCurrentUser() async {
    return _currentUser;
  }

  Future<void> logout() async {
    _currentUser = null;
  }
}

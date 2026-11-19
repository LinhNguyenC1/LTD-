import '../db_helper.dart';

class UserDao {
  final DatabaseHelper _dbHelper;

  UserDao({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<int> insertUser(Map<String, dynamic> userMap) async {
    final db = await _dbHelper.database;
    return await db.insert('users', userMap);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'LOWER(email) = LOWER(?)',
      whereArgs: [email.trim()],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'LOWER(username) = LOWER(?)',
      whereArgs: [username.trim()],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<Map<String, dynamic>?> verifyUser(
    String emailOrUsername,
    String passwordHash,
  ) async {
    final db = await _dbHelper.database;
    final identifier = emailOrUsername.trim();
    final results = await db.query(
      'users',
      where:
          '(LOWER(email) = LOWER(?) OR LOWER(username) = LOWER(?)) AND password_hash = ?',
      whereArgs: [identifier, identifier, passwordHash],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await _dbHelper.database;
    return await db.query('users', orderBy: 'id ASC');
  }

  Future<int> deleteUser(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

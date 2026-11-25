import 'package:sqflite/sqflite.dart';
import '../db_helper.dart';

class SessionDao {
  final DatabaseHelper _dbHelper;

  SessionDao({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<int?> getCurrentUserId() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'app_session',
      where: 'id = 1',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first['current_user_id'] as int?;
  }

  Future<void> setCurrentUserId(int? userId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    await db.insert(
      'app_session',
      {
        'id': 1,
        'current_user_id': userId,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearSession() async {
    final db = await _dbHelper.database;
    await db.delete(
      'app_session',
      where: 'id = 1',
    );
  }
}

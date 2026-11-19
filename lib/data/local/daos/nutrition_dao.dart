import 'package:sqflite/sqflite.dart';
import '../db_helper.dart';

class NutritionDao {
  final DatabaseHelper _dbHelper;

  NutritionDao({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<int> insertOrUpdateNutrition(Map<String, dynamic> nutritionMap) async {
    final db = await _dbHelper.database;
    final productId = nutritionMap['product_id'] as int;

    final existing = await getNutritionByProductId(productId);
    if (existing != null) {
      final existingId = existing['id'] as int;
      await db.update(
        'product_nutrition',
        nutritionMap,
        where: 'product_id = ?',
        whereArgs: [productId],
      );
      return existingId;
    } else {
      return await db.insert(
        'product_nutrition',
        nutritionMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<Map<String, dynamic>?> getNutritionByProductId(int productId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'product_nutrition',
      where: 'product_id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<int> deleteNutritionByProductId(int productId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'product_nutrition',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
  }
}

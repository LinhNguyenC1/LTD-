import 'package:sqflite/sqflite.dart';
import '../db_helper.dart';

class ProductDao {
  final DatabaseHelper _dbHelper;

  ProductDao({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<int> insertProduct(Map<String, dynamic> productMap) async {
    final db = await _dbHelper.database;
    if (productMap['id'] == null && productMap['barcode'] != null) {
      final existing =
          await getProductByBarcode(productMap['barcode'] as String);
      if (existing != null) {
        final existingId = existing['id'] as int;
        await db.update(
          'cached_product',
          productMap,
          where: 'id = ?',
          whereArgs: [existingId],
        );
        return existingId;
      }
    }
    return await db.insert(
      'cached_product',
      productMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'cached_product',
      where: 'barcode = ?',
      whereArgs: [barcode.trim()],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<Map<String, dynamic>?> getProductById(int id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'cached_product',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final db = await _dbHelper.database;
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return await getAllProducts();
    }
    final pattern = '%$trimmed%';
    return await db.query(
      'cached_product',
      where: 'product_name LIKE ? OR brand LIKE ? OR barcode LIKE ?',
      whereArgs: [pattern, pattern, pattern],
      orderBy: 'id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await _dbHelper.database;
    return await db.query('cached_product', orderBy: 'id DESC');
  }

  Future<int> deleteProduct(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'cached_product',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllProducts() async {
    final db = await _dbHelper.database;
    return await db.delete('cached_product');
  }
}

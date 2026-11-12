import '../db_helper.dart';
import '../../models/scan_history_item.dart';

class HistoryDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<ScanHistoryItem>> getAllHistory() async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery('''
      SELECT 
        h.id,
        h.product_id,
        h.evaluation_status,
        h.violation_reasons,
        h.scanned_at,
        p.product_name,
        p.brand,
        p.image_url
      FROM scan_history h
      INNER JOIN cached_product p ON h.product_id = p.id
      ORDER BY h.scanned_at DESC
    ''');

    return result.map((map) => ScanHistoryItem.fromMap(map)).toList();
  }

  Future<int> deleteHistoryItem(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'scan_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

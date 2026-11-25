import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:an_lanh/data/local/db_helper.dart';

bool _isInitialized = false;

void setupTestDatabaseFactory() {
  if (!_isInitialized) {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _isInitialized = true;
  }
}

Future<Database> createInMemoryTestDatabase({bool seedData = true}) async {
  setupTestDatabaseFactory();
  final db = await openDatabase(
    inMemoryDatabasePath,
    version: 4,
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    },
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE NOT NULL,
          email TEXT UNIQUE NOT NULL,
          password_hash TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_profile (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER UNIQUE,
          is_guest INTEGER NOT NULL DEFAULT 0,
          name TEXT NOT NULL,
          nutrition_targets TEXT,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_allergen (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          profile_id INTEGER NOT NULL,
          allergen_code TEXT NOT NULL,
          FOREIGN KEY (profile_id) REFERENCES user_profile (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_session (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          current_user_id INTEGER,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (current_user_id) REFERENCES users (id) ON DELETE SET NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS cached_product (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          barcode TEXT,
          product_name TEXT NOT NULL,
          brand TEXT,
          image_url TEXT,
          ingredients_text TEXT,
          serving_size TEXT,
          nutriscore_grade TEXT,
          is_incomplete INTEGER NOT NULL DEFAULT 0,
          missing_fields TEXT,
          cached_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS product_nutrition (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER NOT NULL UNIQUE,
          nutrition_data TEXT NOT NULL,
          FOREIGN KEY (product_id) REFERENCES cached_product (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS scan_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER NOT NULL,
          evaluation_status TEXT NOT NULL,
          violation_reasons TEXT,
          scanned_at TEXT NOT NULL,
          FOREIGN KEY (product_id) REFERENCES cached_product (id) ON DELETE CASCADE
        )
      ''');

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_product_barcode ON cached_product(barcode)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_history_product ON scan_history(product_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_history_scanned_at ON scan_history(scanned_at DESC)',
      );

      if (seedData) {
        final now = DateTime.now().toIso8601String();

        final guestProfileId = await db.insert('user_profile', {
          'user_id': null,
          'is_guest': 1,
          'name': 'Linh',
          'nutrition_targets': jsonEncode({'sugars': 10.0, 'sodium': 0.30}),
          'updated_at': now,
        });

        await db.insert('user_allergen', {
          'profile_id': guestProfileId,
          'allergen_code': 'milk',
        });
        await db.insert('user_allergen', {
          'profile_id': guestProfileId,
          'allergen_code': 'peanuts',
        });

        final productId1 = await db.insert('cached_product', {
          'barcode': '8934567890123',
          'product_name': 'Bánh yến mạch cacao',
          'brand': 'Mộc Hạt',
          'ingredients_text':
              'Yến mạch 45%, bột mì, đường, dầu cọ, bột sữa 8%, cacao 4%, lecithin đậu nành, muối',
          'serving_size': '100g',
          'nutriscore_grade': 'c',
          'is_incomplete': 0,
          'cached_at': now,
        });

        await db.insert('product_nutrition', {
          'product_id': productId1,
          'nutrition_data': jsonEncode({
            'energy_kcal': 450,
            'total_fat': 16.5,
            'saturated_fat': 7.2,
            'carbohydrate': 64.0,
            'sugars': 18.0,
            'protein': 7.5,
            'sodium': 0.42,
          }),
        });

        await db.insert('scan_history', {
          'product_id': productId1,
          'evaluation_status': 'VIOLATION',
          'violation_reasons':
              'Chứa bột sữa (trùng dị ứng sữa); Đường 18g/100g vượt ngưỡng',
          'scanned_at': now,
        });

        final productId2 = await db.insert('cached_product', {
          'barcode': '8934567890456',
          'product_name': 'Bánh yến mạch nguyên bản',
          'brand': 'An Mộc',
          'ingredients_text':
              'Yến mạch nguyên cám 70%, hạt bí, mật ong rừng, dầu hướng dương, muối biển',
          'serving_size': '100g',
          'nutriscore_grade': 'b',
          'is_incomplete': 0,
          'cached_at': now,
        });

        await db.insert('product_nutrition', {
          'product_id': productId2,
          'nutrition_data': jsonEncode({
            'energy_kcal': 380,
            'total_fat': 9.0,
            'saturated_fat': 1.5,
            'carbohydrate': 60.0,
            'sugars': 4.2,
            'protein': 11.0,
            'sodium': 0.12,
          }),
        });
      }
    },
  );

  DatabaseHelper.setTestDatabase(db);
  return db;
}

Future<void> tearDownTestDatabase(Database? db) async {
  if (db != null && db.isOpen) {
    await db.close();
  }
  await DatabaseHelper.reset();
}

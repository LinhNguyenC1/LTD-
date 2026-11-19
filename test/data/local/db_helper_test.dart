import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:an_lanh/data/local/db_helper.dart';
import '../../helpers/test_database_helper.dart';

void main() {
  late Database db;

  setUpAll(() {
    setupTestDatabaseFactory();
  });

  setUp(() async {
    db = await createInMemoryTestDatabase(seedData: true);
  });

  tearDown(() async {
    await DatabaseHelper.reset();
  });

  group('DatabaseHelper Schema & Constraints', () {
    test('all 6 tables are created', () async {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );
      final tableNames = tables.map((row) => row['name'] as String).toSet();

      expect(
        tableNames,
        containsAll([
          'users',
          'user_profile',
          'user_allergen',
          'cached_product',
          'product_nutrition',
          'scan_history',
        ]),
      );
    });

    test('foreign keys are enabled via PRAGMA', () async {
      final pragmaResult = await db.rawQuery('PRAGMA foreign_keys');
      expect(pragmaResult.first.values.first, 1);
    });

    test('users table enforces unique username and unique email', () async {
      final now = DateTime.now().toIso8601String();
      await db.insert('users', {
        'username': 'unique_user',
        'email': 'unique@example.com',
        'password_hash': 'hash123',
        'created_at': now,
      });

      // Duplicate email must fail
      expect(
        () async => await db.insert('users', {
          'username': 'another_user',
          'email': 'unique@example.com',
          'password_hash': 'hash456',
          'created_at': now,
        }),
        throwsA(isA<DatabaseException>()),
      );

      // Duplicate username must fail
      expect(
        () async => await db.insert('users', {
          'username': 'unique_user',
          'email': 'another@example.com',
          'password_hash': 'hash789',
          'created_at': now,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('product_nutrition enforces foreign key on product_id', () async {
      expect(
        () async => await db.insert('product_nutrition', {
          'product_id': 99999,
          'nutrition_data': jsonEncode({'sugars': 10}),
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('product_nutrition enforces UNIQUE constraint on product_id', () async {
      final now = DateTime.now().toIso8601String();
      final pId = await db.insert('cached_product', {
        'product_name': 'Test Product',
        'cached_at': now,
      });

      await db.insert('product_nutrition', {
        'product_id': pId,
        'nutrition_data': jsonEncode({'sugars': 5}),
      });

      // Second insert with same product_id without conflictAlgorithm must fail
      expect(
        () async => await db.insert('product_nutrition', {
          'product_id': pId,
          'nutrition_data': jsonEncode({'sugars': 15}),
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('cascade delete removes product_nutrition and scan_history when product deleted',
        () async {
      final now = DateTime.now().toIso8601String();
      final pId = await db.insert('cached_product', {
        'barcode': '9999999999999',
        'product_name': 'Cascade Test Item',
        'cached_at': now,
      });

      await db.insert('product_nutrition', {
        'product_id': pId,
        'nutrition_data': jsonEncode({'energy_kcal': 100}),
      });

      await db.insert('scan_history', {
        'product_id': pId,
        'evaluation_status': 'SAFE',
        'scanned_at': now,
      });

      // Confirm existence
      final nutBefore = await db.query(
        'product_nutrition',
        where: 'product_id = ?',
        whereArgs: [pId],
      );
      final histBefore = await db.query(
        'scan_history',
        where: 'product_id = ?',
        whereArgs: [pId],
      );
      expect(nutBefore.length, 1);
      expect(histBefore.length, 1);

      // Delete parent product
      await db.delete('cached_product', where: 'id = ?', whereArgs: [pId]);

      // Confirm cascaded deletion
      final nutAfter = await db.query(
        'product_nutrition',
        where: 'product_id = ?',
        whereArgs: [pId],
      );
      final histAfter = await db.query(
        'scan_history',
        where: 'product_id = ?',
        whereArgs: [pId],
      );
      expect(nutAfter, isEmpty);
      expect(histAfter, isEmpty);
    });

    test('all 3 performance indexes exist', () async {
      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index'",
      );
      final indexNames = indexes.map((row) => row['name'] as String).toSet();

      expect(
        indexNames,
        containsAll([
          'idx_product_barcode',
          'idx_history_product',
          'idx_history_scanned_at',
        ]),
      );
    });

    test('seed data exists and is populated correctly', () async {
      final p1 = await db.query(
        'cached_product',
        where: 'barcode = ?',
        whereArgs: ['8934567890123'],
      );
      expect(p1.length, 1);
      expect(p1.first['product_name'], 'Bánh yến mạch cacao');

      final p2 = await db.query(
        'cached_product',
        where: 'barcode = ?',
        whereArgs: ['8934567890456'],
      );
      expect(p2.length, 1);
      expect(p2.first['product_name'], 'Bánh yến mạch nguyên bản');

      final nut1 = await db.query(
        'product_nutrition',
        where: 'product_id = ?',
        whereArgs: [p1.first['id']],
      );
      expect(nut1.length, 1);
      final data1 = jsonDecode(nut1.first['nutrition_data'] as String);
      expect(data1['sugars'], 18.0);
    });
  });
}

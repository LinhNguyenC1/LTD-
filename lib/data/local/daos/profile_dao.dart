import 'package:sqflite/sqflite.dart';
import '../db_helper.dart';
import '../../models/user_profile.dart';
import '../../models/user_allergen.dart';

class ProfileDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> upsertProfile(UserProfile profile) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      await txn.insert(
        'user_profile',
        profile.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.delete(
        'user_allergen',
        where: 'profile_id = ?',
        whereArgs: [profile.id],
      );

      for (final code in profile.allergens) {
        final allergen = UserAllergen(
          profileId: profile.id,
          allergenCode: code,
        );
        await txn.insert('user_allergen', allergen.toMap());
      }
    });
  }

  Future<UserProfile?> getProfile() async {
    final db = await _dbHelper.database;

    final profileMaps = await db.query(
      'user_profile',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (profileMaps.isEmpty) return null;

    final allergenMaps = await db.query(
      'user_allergen',
      where: 'profile_id = ?',
      whereArgs: [1],
    );

    final allergenCodes =
        allergenMaps.map((row) => row['allergen_code'] as String).toList();

    return UserProfile.fromMap(profileMaps.first, allergens: allergenCodes);
  }

  Future<int> deleteProfile() async {
    final db = await _dbHelper.database;
    return await db.delete(
      'user_profile',
      where: 'id = ?',
      whereArgs: [1],
    );
  }
}

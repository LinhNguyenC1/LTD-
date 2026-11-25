import '../db_helper.dart';
import '../../models/user_profile.dart';
import '../../models/user_allergen.dart';

class ProfileDao {
  final DatabaseHelper _dbHelper;

  ProfileDao({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<UserProfile?> getProfile([int? id]) async {
    if (id != null) {
      return await getProfileByUserId(id);
    }
    return await getGuestProfile();
  }

  Future<void> upsertProfile(UserProfile profile) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      int profileId = profile.id;

      if (profile.userId != null) {
        final existing = await txn.query(
          'user_profile',
          where: 'user_id = ?',
          whereArgs: [profile.userId],
          limit: 1,
        );

        if (existing.isNotEmpty) {
          profileId = existing.first['id'] as int;
          await txn.update(
            'user_profile',
            {
              'name': profile.name,
              'nutrition_targets': profile.toMap()['nutrition_targets'],
              'updated_at': profile.updatedAt,
            },
            where: 'id = ?',
            whereArgs: [profileId],
          );
        } else {
          profileId = await txn.insert('user_profile', {
            'user_id': profile.userId,
            'is_guest': 0,
            'name': profile.name,
            'nutrition_targets': profile.toMap()['nutrition_targets'],
            'updated_at': profile.updatedAt,
          });
        }
      } else {
        final existingGuest = await txn.query(
          'user_profile',
          where: 'is_guest = 1 OR user_id IS NULL',
          limit: 1,
        );

        if (existingGuest.isNotEmpty) {
          profileId = existingGuest.first['id'] as int;
          await txn.update(
            'user_profile',
            {
              'name': profile.name,
              'nutrition_targets': profile.toMap()['nutrition_targets'],
              'updated_at': profile.updatedAt,
            },
            where: 'id = ?',
            whereArgs: [profileId],
          );
        } else {
          profileId = await txn.insert('user_profile', {
            'user_id': null,
            'is_guest': 1,
            'name': profile.name,
            'nutrition_targets': profile.toMap()['nutrition_targets'],
            'updated_at': profile.updatedAt,
          });
        }
      }

      await txn.delete(
        'user_allergen',
        where: 'profile_id = ?',
        whereArgs: [profileId],
      );

      for (final code in profile.allergens) {
        final allergen = UserAllergen(
          profileId: profileId,
          allergenCode: code,
        );
        await txn.insert('user_allergen', allergen.toMap());
      }
    });
  }

  Future<UserProfile?> getGuestProfile() async {
    final db = await _dbHelper.database;
    final profileMaps = await db.query(
      'user_profile',
      where: 'is_guest = 1 OR user_id IS NULL',
      limit: 1,
    );

    if (profileMaps.isEmpty) return null;

    final profileId = profileMaps.first['id'] as int;
    final allergenMaps = await db.query(
      'user_allergen',
      where: 'profile_id = ?',
      whereArgs: [profileId],
    );

    final allergenCodes =
        allergenMaps.map((row) => row['allergen_code'] as String).toList();

    return UserProfile.fromMap(
      profileMaps.first,
      allergens: allergenCodes,
    );
  }

  Future<UserProfile?> getProfileByUserId(int userId) async {
    final db = await _dbHelper.database;
    final profileMaps = await db.query(
      'user_profile',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (profileMaps.isEmpty) return null;

    final profileId = profileMaps.first['id'] as int;
    final allergenMaps = await db.query(
      'user_allergen',
      where: 'profile_id = ?',
      whereArgs: [profileId],
    );

    final allergenCodes =
        allergenMaps.map((row) => row['allergen_code'] as String).toList();

    return UserProfile.fromMap(
      profileMaps.first,
      allergens: allergenCodes,
    );
  }

  Future<int> deleteProfileByUserId(int userId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'user_profile',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deleteGuestProfile() async {
    final db = await _dbHelper.database;
    return await db.delete(
      'user_profile',
      where: 'is_guest = 1 OR user_id IS NULL',
    );
  }
}

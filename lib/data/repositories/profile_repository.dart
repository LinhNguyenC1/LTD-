import '../local/daos/profile_dao.dart';
import '../models/user_profile.dart';

class ProfileRepository {
  final ProfileDao _profileDao;

  ProfileRepository({ProfileDao? profileDao})
      : _profileDao = profileDao ?? ProfileDao();

  Future<UserProfile?> fetchUserProfile([int? userId]) async {
    final targetId = userId ?? 1;
    return await _profileDao.getProfile(targetId);
  }

  Future<void> saveUserProfile({
    int? userId,
    required String name,
    required List<String> allergens,
    required Map<String, double> nutritionTargets,
  }) async {
    final targetId = userId ?? 1;
    final profile = UserProfile(
      id: targetId,
      name: name.trim().isEmpty ? 'Người dùng' : name.trim(),
      allergens: allergens,
      nutritionTargets: nutritionTargets,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _profileDao.upsertProfile(profile);
  }

  Future<void> clearUserProfile([int? userId]) async {
    final targetId = userId ?? 1;
    await _profileDao.deleteProfile(targetId);
  }
}

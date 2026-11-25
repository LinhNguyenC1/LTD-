import '../local/daos/profile_dao.dart';
import '../models/user_profile.dart';

class ProfileRepository {
  final ProfileDao _profileDao;

  ProfileRepository({ProfileDao? profileDao})
      : _profileDao = profileDao ?? ProfileDao();

  Future<UserProfile?> fetchUserProfile([int? userId]) async {
    if (userId != null) {
      return await _profileDao.getProfileByUserId(userId);
    }
    return await _profileDao.getGuestProfile();
  }

  Future<void> saveUserProfile({
    int? userId,
    required String name,
    required List<String> allergens,
    required Map<String, double> nutritionTargets,
  }) async {
    final profile = UserProfile(
      userId: userId,
      isGuest: userId == null,
      name: name.trim().isEmpty ? 'Linh' : name.trim(),
      allergens: allergens,
      nutritionTargets: nutritionTargets,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _profileDao.upsertProfile(profile);
  }

  Future<void> clearUserProfile([int? userId]) async {
    if (userId != null) {
      await _profileDao.deleteProfileByUserId(userId);
    } else {
      await _profileDao.deleteGuestProfile();
    }
  }
}

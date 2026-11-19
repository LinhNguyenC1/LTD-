import '../local/daos/profile_dao.dart';
import '../models/user_profile.dart';

class ProfileRepository {
  final ProfileDao _profileDao;

  ProfileRepository({ProfileDao? profileDao})
      : _profileDao = profileDao ?? ProfileDao();

  Future<UserProfile?> fetchUserProfile() async {
    return await _profileDao.getProfile();
  }

  Future<void> saveUserProfile({
    required String name,
    required List<String> allergens,
    required Map<String, double> nutritionTargets,
  }) async {
    final profile = UserProfile(
      id: 1,
      name: name.trim().isEmpty ? 'Người dùng' : name.trim(),
      allergens: allergens,
      nutritionTargets: nutritionTargets,
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _profileDao.upsertProfile(profile);
  }

  Future<void> clearUserProfile() async {
    await _profileDao.deleteProfile();
  }
}

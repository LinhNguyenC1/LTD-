import 'package:flutter/foundation.dart';
import '../../data/models/user.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/profile_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _repository;
  int? _activeUserId;

  ProfileViewModel({ProfileRepository? profileRepository})
      : _repository = profileRepository ?? ProfileRepository();

  UserProfile? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasProfile => _profile != null;
  int? get activeUserId => _activeUserId;
  bool get isSynced => _activeUserId != null;

  Future<void> loadProfile({int? userId}) async {
    if (userId != null) {
      _activeUserId = userId;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _repository.fetchUserProfile(_activeUserId);
    } catch (e) {
      _errorMessage = 'Lỗi khi tải hồ sơ: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> syncOnLogin(User user) async {
    final uid = user.id;
    if (uid == null) return;
    _activeUserId = uid;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final existingAccountProfile = await _repository.fetchUserProfile(uid);
      if (existingAccountProfile != null) {
        _profile = existingAccountProfile;
      } else {
        final guestProfile = await _repository.fetchUserProfile(null);
        final profileToSave = UserProfile(
          userId: uid,
          isGuest: false,
          name: (guestProfile != null && guestProfile.name.trim().isNotEmpty)
              ? guestProfile.name
              : user.username,
          allergens: guestProfile?.allergens ?? [],
          nutritionTargets: guestProfile?.nutritionTargets ?? {},
          updatedAt: DateTime.now().toIso8601String(),
        );
        await _repository.saveUserProfile(
          userId: uid,
          name: profileToSave.name,
          allergens: profileToSave.allergens,
          nutritionTargets: profileToSave.nutritionTargets,
        );
        _profile = await _repository.fetchUserProfile(uid);
      }
    } catch (e) {
      _errorMessage = 'Lỗi khi đồng bộ hồ sơ vào tài khoản: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> onLogout() async {
    _activeUserId = null;
    await loadProfile(userId: null);
  }

  Future<bool> saveProfile({
    int? userId,
    required String name,
    required List<String> allergens,
    required Map<String, double> nutritionTargets,
  }) async {
    final targetId = userId ?? _activeUserId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.saveUserProfile(
        userId: targetId,
        name: name,
        allergens: allergens,
        nutritionTargets: nutritionTargets,
      );
      _profile = await _repository.fetchUserProfile(targetId);
      return true;
    } catch (e) {
      _errorMessage = 'Không thể lưu hồ sơ: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProfile({int? userId}) async {
    final targetId = userId ?? _activeUserId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.clearUserProfile(targetId);
      _profile = null;
      return true;
    } catch (e) {
      _errorMessage = 'Không thể xóa hồ sơ: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

import 'package:flutter/foundation.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/profile_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _repository;

  ProfileViewModel({ProfileRepository? profileRepository})
      : _repository = profileRepository ?? ProfileRepository();

  UserProfile? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasProfile => _profile != null;

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _repository.fetchUserProfile();
    } catch (e) {
      _errorMessage = 'Lỗi khi tải hồ sơ: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveProfile({
    required String name,
    required List<String> allergens,
    required Map<String, double> nutritionTargets,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.saveUserProfile(
        name: name,
        allergens: allergens,
        nutritionTargets: nutritionTargets,
      );
      _profile = await _repository.fetchUserProfile();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể lưu hồ sơ: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.clearUserProfile();
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

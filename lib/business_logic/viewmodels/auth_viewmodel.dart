import 'package:flutter/foundation.dart';
import '../../core/services/notification_service.dart';
import '../../core/validators/form_validator.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final NotificationService _notificationService;
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  AuthViewModel({
    AuthRepository? authRepository,
    NotificationService? notificationService,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _notificationService =
            notificationService ?? NotificationService.instance;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isAuthenticated => _currentUser != null;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _authRepository.getCurrentUser();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String emailOrUsername, String password) async {
    final clean = emailOrUsername.trim();
    if (clean.isEmpty || password.isEmpty) {
      _errorMessage = 'Vui lòng nhập đầy đủ thông tin đăng nhập';
      _successMessage = null;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final user = await _authRepository.login(clean, password);
      if (user != null) {
        _currentUser = user;
        _successMessage = 'Đăng nhập thành công';
        try {
          await _notificationService.showLoginWelcome(user.username);
        } catch (_) {}
        return true;
      }
      _errorMessage = 'Email/tên đăng nhập hoặc mật khẩu không chính xác';
      return false;
    } catch (e) {
      _errorMessage = 'Lỗi hệ thống khi đăng nhập: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String confirmPassword,
  }) async {
    final nameErr = FormValidator.validateName(name);
    if (nameErr != null) {
      _errorMessage = nameErr;
      _successMessage = null;
      notifyListeners();
      return false;
    }

    final emailErr = FormValidator.validateEmail(email);
    if (emailErr != null) {
      _errorMessage = emailErr;
      _successMessage = null;
      notifyListeners();
      return false;
    }

    final passErr = FormValidator.validatePassword(password);
    if (passErr != null) {
      _errorMessage = passErr;
      _successMessage = null;
      notifyListeners();
      return false;
    }

    final confirmErr =
        FormValidator.validateConfirmPassword(password, confirmPassword);
    if (confirmErr != null) {
      _errorMessage = confirmErr;
      _successMessage = null;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final success = await _authRepository.register(email, password, name);
      if (success) {
        _currentUser = await _authRepository.getCurrentUser();
        _successMessage = 'Đăng ký tài khoản thành công';
        try {
          await _notificationService.showRegisterWelcome(name);
        } catch (_) {}
        return true;
      }
      _errorMessage =
          'Đăng ký thất bại. Email hoặc tên tài khoản có thể đã được sử dụng';
      return false;
    } catch (e) {
      _errorMessage = 'Lỗi hệ thống khi đăng ký: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authRepository.logout();
      _currentUser = null;
      _errorMessage = null;
      _successMessage = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

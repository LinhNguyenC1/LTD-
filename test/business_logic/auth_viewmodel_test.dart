import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:an_lanh/business_logic/viewmodels/auth_viewmodel.dart';
import 'package:an_lanh/data/models/user.dart';
import 'package:an_lanh/data/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late AuthViewModel viewModel;

  setUp(() {
    mockRepo = MockAuthRepository();
    viewModel = AuthViewModel(authRepository: mockRepo);
  });

  group('AuthViewModel - Initial State', () {
    test('initial values are correct', () {
      expect(viewModel.currentUser, isNull);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.successMessage, isNull);
      expect(viewModel.isAuthenticated, isFalse);
    });
  });

  group('AuthViewModel - loadCurrentUser', () {
    test('loads user successfully', () async {
      final user = User(
        id: 1,
        username: 'linh',
        email: 'linh@example.com',
        passwordHash: 'hash',
        createdAt: '2026-01-01',
      );
      when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => user);

      await viewModel.loadCurrentUser();

      expect(viewModel.currentUser, equals(user));
      expect(viewModel.isAuthenticated, isTrue);
      expect(viewModel.isLoading, isFalse);
    });
  });

  group('AuthViewModel - login', () {
    test('returns false when fields are empty', () async {
      final result = await viewModel.login('', '');
      expect(result, isFalse);
      expect(viewModel.errorMessage, contains('đầy đủ'));
      expect(viewModel.isAuthenticated, isFalse);
      verifyNever(() => mockRepo.login(any(), any()));
    });

    test('returns false when credentials invalid', () async {
      when(() => mockRepo.login('wrong@test.com', 'secret123'))
          .thenAnswer((_) async => null);

      final result = await viewModel.login('wrong@test.com', 'secret123');

      expect(result, isFalse);
      expect(viewModel.errorMessage, contains('không chính xác'));
      expect(viewModel.isAuthenticated, isFalse);
    });

    test('returns true when login succeeds', () async {
      final user = User(
        id: 10,
        username: 'alex',
        email: 'alex@test.com',
        passwordHash: 'hash',
        createdAt: '2026-01-01',
      );
      when(() => mockRepo.login('alex@test.com', 'secret123'))
          .thenAnswer((_) async => user);

      final result = await viewModel.login('alex@test.com', 'secret123');

      expect(result, isTrue);
      expect(viewModel.currentUser, equals(user));
      expect(viewModel.isAuthenticated, isTrue);
      expect(viewModel.successMessage, contains('thành công'));
      expect(viewModel.errorMessage, isNull);
    });

    test('handles exception properly', () async {
      when(() => mockRepo.login(any(), any()))
          .thenThrow(Exception('DB connection failed'));

      final result = await viewModel.login('alex@test.com', 'secret123');

      expect(result, isFalse);
      expect(viewModel.errorMessage, contains('Lỗi hệ thống'));
      expect(viewModel.isAuthenticated, isFalse);
    });
  });

  group('AuthViewModel - register', () {
    test('returns false on validation failure (empty name)', () async {
      final result = await viewModel.register(
        email: 'test@example.com',
        password: 'password123',
        name: '',
        confirmPassword: 'password123',
      );
      expect(result, isFalse);
      expect(viewModel.errorMessage, contains('Họ tên không được để trống'));
    });

    test('returns false on validation failure (invalid email)', () async {
      final result = await viewModel.register(
        email: 'not-an-email',
        password: 'password123',
        name: 'Test Name',
        confirmPassword: 'password123',
      );
      expect(result, isFalse);
      expect(viewModel.errorMessage, contains('Email không đúng định dạng'));
    });

    test('returns false on validation failure (short password)', () async {
      final result = await viewModel.register(
        email: 'test@example.com',
        password: '123',
        name: 'Test Name',
        confirmPassword: '123',
      );
      expect(result, isFalse);
      expect(viewModel.errorMessage, contains('ít nhất 6 ký tự'));
    });

    test('returns false on validation failure (password mismatch)', () async {
      final result = await viewModel.register(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test Name',
        confirmPassword: 'password456',
      );
      expect(result, isFalse);
      expect(viewModel.errorMessage, contains('Mật khẩu xác nhận không khớp'));
    });

    test('returns false when repository register returns false', () async {
      when(() => mockRepo.register(any(), any(), any()))
          .thenAnswer((_) async => false);

      final result = await viewModel.register(
        email: 'existing@example.com',
        password: 'password123',
        name: 'Existing',
        confirmPassword: 'password123',
      );

      expect(result, isFalse);
      expect(viewModel.errorMessage, contains('Đăng ký thất bại'));
    });

    test('returns true when registration succeeds', () async {
      final user = User(
        id: 2,
        username: 'NewUser',
        email: 'new@example.com',
        passwordHash: 'hash',
        createdAt: '2026-01-01',
      );
      when(() => mockRepo.register('new@example.com', 'password123', 'NewUser'))
          .thenAnswer((_) async => true);
      when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => user);

      final result = await viewModel.register(
        email: 'new@example.com',
        password: 'password123',
        name: 'NewUser',
        confirmPassword: 'password123',
      );

      expect(result, isTrue);
      expect(viewModel.currentUser, equals(user));
      expect(viewModel.isAuthenticated, isTrue);
      expect(viewModel.successMessage, contains('thành công'));
    });
  });

  group('AuthViewModel - logout', () {
    test('clears current user and messages', () async {
      when(() => mockRepo.logout()).thenAnswer((_) async {});

      await viewModel.logout();

      expect(viewModel.currentUser, isNull);
      expect(viewModel.isAuthenticated, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.successMessage, isNull);
      verify(() => mockRepo.logout()).called(1);
    });
  });

  group('AuthViewModel - utility methods', () {
    test('clearError and clearSuccess work correctly', () async {
      await viewModel.login('', '');
      expect(viewModel.errorMessage, isNotNull);
      viewModel.clearError();
      expect(viewModel.errorMessage, isNull);

      viewModel.clearSuccess();
      expect(viewModel.successMessage, isNull);
    });
  });
}

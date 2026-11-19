import 'package:flutter_test/flutter_test.dart';
import 'package:an_lanh/data/repositories/auth_repository.dart';
import 'package:an_lanh/data/local/daos/user_dao.dart';
import 'package:an_lanh/data/local/db_helper.dart';
import '../../helpers/test_database_helper.dart';

void main() {
  late AuthRepository authRepository;
  late UserDao userDao;

  setUpAll(() {
    setupTestDatabaseFactory();
  });

  setUp(() async {
    await createInMemoryTestDatabase(seedData: false);
    userDao = UserDao();
    authRepository = AuthRepository(userDao: userDao);
  });

  tearDown(() async {
    await DatabaseHelper.reset();
  });

  group('AuthRepository Tests', () {
    test('register creates user, hashes password, sets currentUser, and returns true',
        () async {
      final success = await authRepository.register(
        'alice@example.com',
        'Secret123!',
        'alice_wonderland',
      );

      expect(success, isTrue);

      final currentUser = await authRepository.getCurrentUser();
      expect(currentUser, isNotNull);
      expect(currentUser!.email, 'alice@example.com');
      expect(currentUser.username, 'alice_wonderland');
      expect(currentUser.id, greaterThan(0));
      // Password must be hashed (SHA-256 is 64 hex chars), NOT stored plaintext
      expect(currentUser.passwordHash, isNot(equals('Secret123!')));
      expect(currentUser.passwordHash.length, 64);
    });

    test('register rejects duplicate email', () async {
      final first = await authRepository.register(
        'dup@example.com',
        'Pass1',
        'user1',
      );
      expect(first, isTrue);

      final second = await authRepository.register(
        'dup@example.com',
        'Pass2',
        'user2',
      );
      expect(second, isFalse);
    });

    test('register rejects duplicate username', () async {
      final first = await authRepository.register(
        'u1@example.com',
        'Pass1',
        'same_name',
      );
      expect(first, isTrue);

      final second = await authRepository.register(
        'u2@example.com',
        'Pass2',
        'same_name',
      );
      expect(second, isFalse);
    });

    test('register rejects empty inputs', () async {
      expect(await authRepository.register('', 'pass', 'name'), isFalse);
      expect(await authRepository.register('email@test.com', '', 'name'), isFalse);
      expect(await authRepository.register('email@test.com', 'pass', ''), isFalse);
    });

    test('login succeeds with correct email and password', () async {
      await authRepository.register(
        'bob@example.com',
        'MyPassword',
        'bob_builder',
      );

      await authRepository.logout();
      expect(await authRepository.getCurrentUser(), isNull);

      final user = await authRepository.login('bob@example.com', 'MyPassword');
      expect(user, isNotNull);
      expect(user!.username, 'bob_builder');
      expect(await authRepository.getCurrentUser(), isNotNull);
    });

    test('login succeeds with correct username and password', () async {
      await authRepository.register(
        'charlie@example.com',
        'CharliePass',
        'charlie_brown',
      );

      await authRepository.logout();

      final user = await authRepository.login('charlie_brown', 'CharliePass');
      expect(user, isNotNull);
      expect(user!.email, 'charlie@example.com');
    });

    test('login fails with wrong password', () async {
      await authRepository.register(
        'david@example.com',
        'DavidPass',
        'david',
      );

      final user = await authRepository.login('david@example.com', 'WrongPass');
      expect(user, isNull);
    });

    test('login fails with unknown user', () async {
      final user = await authRepository.login('nonexistent@example.com', 'AnyPass');
      expect(user, isNull);
    });

    test('logout clears currentUser session', () async {
      await authRepository.register('test@test.com', 'p', 'test');
      expect(await authRepository.getCurrentUser(), isNotNull);

      await authRepository.logout();
      expect(await authRepository.getCurrentUser(), isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:an_lanh/data/local/daos/user_dao.dart';
import 'package:an_lanh/data/repositories/auth_repository.dart';
import '../helpers/test_database_helper.dart';

void main() {
  late Database db;
  late UserDao userDao;
  late AuthRepository authRepository;

  setUpAll(() {
    setupTestDatabaseFactory();
  });

  setUp(() async {
    db = await createInMemoryTestDatabase(seedData: false);
    userDao = UserDao();
    authRepository = AuthRepository(userDao: userDao);
  });

  tearDown(() async {
    await tearDownTestDatabase(db);
  });

  group('Tier 1: Auth Coverage Tests', () {
    test('T1_AUTH_01: Successful user registration persists to database', () async {
      final success = await authRepository.register(
        'lanh@anlanh.vn',
        'securePass123',
        'Nguyễn Văn Lành',
      );

      expect(success, isTrue);

      final storedUser = await userDao.getUserByEmail('lanh@anlanh.vn');
      expect(storedUser, isNotNull);
      expect(storedUser!['email'], 'lanh@anlanh.vn');
      expect(storedUser['username'], 'Nguyễn Văn Lành');
      expect(storedUser['password_hash'], isNotEmpty);
      expect(storedUser['created_at'], isNotEmpty);
    });

    test('T1_AUTH_02: Successful user login yields authenticated User session', () async {
      await authRepository.register(
        'user@anlanh.vn',
        'mySecret999',
        'Linh Trần',
      );

      final loggedInUser = await authRepository.login('user@anlanh.vn', 'mySecret999');

      expect(loggedInUser, isNotNull);
      expect(loggedInUser!.email, 'user@anlanh.vn');
      expect(loggedInUser.username, 'Linh Trần');
      expect(loggedInUser.id, isNotNull);

      final current = await authRepository.getCurrentUser();
      expect(current, equals(loggedInUser));
    });

    test('T1_AUTH_03: Login attempt with incorrect password fails and leaves session null', () async {
      await authRepository.register(
        'member@anlanh.vn',
        'correctPassword',
        'Member One',
      );

      // Reset active session
      await authRepository.logout();

      final result = await authRepository.login('member@anlanh.vn', 'wrongPassword');

      expect(result, isNull);
      final current = await authRepository.getCurrentUser();
      expect(current, isNull);
    });

    test('T1_AUTH_04: Session persistence returns active user, and logout() clears session state', () async {
      await authRepository.register(
        'session@anlanh.vn',
        'sessionPass1',
        'Session User',
      );

      final activeUser = await authRepository.getCurrentUser();
      expect(activeUser, isNotNull);
      expect(activeUser!.email, 'session@anlanh.vn');

      await authRepository.logout();
      final afterLogout = await authRepository.getCurrentUser();
      expect(afterLogout, isNull);
    });

    test('T1_AUTH_05: Registration fails when email already exists (duplicate rejection)', () async {
      final firstAttempt = await authRepository.register(
        'duplicate@anlanh.vn',
        'initialPass123',
        'First Holder',
      );
      expect(firstAttempt, isTrue);

      final duplicateAttempt = await authRepository.register(
        'duplicate@anlanh.vn',
        'differentPass456',
        'Second Holder',
      );
      expect(duplicateAttempt, isFalse);

      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM users WHERE email = ?', ['duplicate@anlanh.vn']),
      );
      expect(count, 1);
    });
  });
}

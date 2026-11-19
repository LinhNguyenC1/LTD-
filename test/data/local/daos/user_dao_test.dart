import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:an_lanh/data/local/daos/user_dao.dart';
import 'package:an_lanh/data/local/db_helper.dart';
import '../../../helpers/test_database_helper.dart';

void main() {
  late UserDao userDao;

  setUpAll(() {
    setupTestDatabaseFactory();
  });

  setUp(() async {
    await createInMemoryTestDatabase(seedData: false);
    userDao = UserDao();
  });

  tearDown(() async {
    await DatabaseHelper.reset();
  });

  group('UserDao Tests', () {
    test('insertUser returns valid id and stores user', () async {
      final now = DateTime.now().toIso8601String();
      final id = await userDao.insertUser({
        'username': 'john_doe',
        'email': 'john@example.com',
        'password_hash': 'hashed_secret',
        'created_at': now,
      });

      expect(id, greaterThan(0));

      final user = await userDao.getUserById(id);
      expect(user, isNotNull);
      expect(user!['username'], 'john_doe');
      expect(user['email'], 'john@example.com');
      expect(user['password_hash'], 'hashed_secret');
      expect(user['created_at'], now);
    });

    test('insertUser throws DatabaseException on duplicate email', () async {
      final now = DateTime.now().toIso8601String();
      await userDao.insertUser({
        'username': 'user_one',
        'email': 'dup@example.com',
        'password_hash': 'h1',
        'created_at': now,
      });

      expect(
        () async => await userDao.insertUser({
          'username': 'user_two',
          'email': 'dup@example.com',
          'password_hash': 'h2',
          'created_at': now,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('insertUser throws DatabaseException on duplicate username', () async {
      final now = DateTime.now().toIso8601String();
      await userDao.insertUser({
        'username': 'dup_user',
        'email': 'user1@example.com',
        'password_hash': 'h1',
        'created_at': now,
      });

      expect(
        () async => await userDao.insertUser({
          'username': 'dup_user',
          'email': 'user2@example.com',
          'password_hash': 'h2',
          'created_at': now,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('getUserByEmail retrieves user case-insensitively', () async {
      final now = DateTime.now().toIso8601String();
      await userDao.insertUser({
        'username': 'alice',
        'email': 'alice@example.com',
        'password_hash': 'alice_hash',
        'created_at': now,
      });

      final exact = await userDao.getUserByEmail('alice@example.com');
      expect(exact, isNotNull);
      expect(exact!['username'], 'alice');

      final upper = await userDao.getUserByEmail('ALICE@EXAMPLE.COM');
      expect(upper, isNotNull);
      expect(upper!['username'], 'alice');

      final notFound = await userDao.getUserByEmail('unknown@example.com');
      expect(notFound, isNull);
    });

    test('getUserByUsername retrieves user case-insensitively', () async {
      final now = DateTime.now().toIso8601String();
      await userDao.insertUser({
        'username': 'BobTheBuilder',
        'email': 'bob@example.com',
        'password_hash': 'bob_hash',
        'created_at': now,
      });

      final exact = await userDao.getUserByUsername('BobTheBuilder');
      expect(exact, isNotNull);
      expect(exact!['email'], 'bob@example.com');

      final lower = await userDao.getUserByUsername('bobthebuilder');
      expect(lower, isNotNull);
      expect(lower!['email'], 'bob@example.com');

      final notFound = await userDao.getUserByUsername('nobody');
      expect(notFound, isNull);
    });

    test('verifyUser validates with email or username and passwordHash', () async {
      final now = DateTime.now().toIso8601String();
      await userDao.insertUser({
        'username': 'charlie',
        'email': 'charlie@example.com',
        'password_hash': 'correct_hash',
        'created_at': now,
      });

      // Verify with email
      final byEmail = await userDao.verifyUser('charlie@example.com', 'correct_hash');
      expect(byEmail, isNotNull);
      expect(byEmail!['username'], 'charlie');

      // Verify with username
      final byUser = await userDao.verifyUser('charlie', 'correct_hash');
      expect(byUser, isNotNull);
      expect(byUser!['email'], 'charlie@example.com');

      // Bad password
      final badPass = await userDao.verifyUser('charlie@example.com', 'wrong_hash');
      expect(badPass, isNull);

      // Unknown user
      final unknown = await userDao.verifyUser('unknown', 'correct_hash');
      expect(unknown, isNull);
    });

    test('getAllUsers and deleteUser', () async {
      final now = DateTime.now().toIso8601String();
      final id1 = await userDao.insertUser({
        'username': 'user1',
        'email': 'u1@example.com',
        'password_hash': 'h1',
        'created_at': now,
      });
      final id2 = await userDao.insertUser({
        'username': 'user2',
        'email': 'u2@example.com',
        'password_hash': 'h2',
        'created_at': now,
      });

      final users = await userDao.getAllUsers();
      expect(users.length, 2);

      final deleted = await userDao.deleteUser(id1);
      expect(deleted, 1);

      final usersAfter = await userDao.getAllUsers();
      expect(usersAfter.length, 1);
      expect(usersAfter.first['id'], id2);
    });
  });
}

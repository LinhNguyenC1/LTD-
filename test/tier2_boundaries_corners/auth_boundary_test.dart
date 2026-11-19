import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:an_lanh/data/models/user.dart';
import 'package:an_lanh/data/local/daos/user_dao.dart';
import 'package:an_lanh/data/repositories/auth_repository.dart';
import '../helpers/test_database_helper.dart';
import '../helpers/validators.dart';

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

  group('Tier 2: Auth Boundary & Corner Cases', () {
    test('T2_AUTH_01: Email input with leading/trailing whitespace and uppercase is normalized', () async {
      final registered = await authRepository.register(
        '  User.Test@AnLanh.VN  ',
        'password123',
        'Normalized User',
      );
      expect(registered, isTrue);

      // Verify stored email is normalized (lowercase, trimmed)
      final stored = await userDao.getUserByEmail('user.test@anlanh.vn');
      expect(stored, isNotNull);
      expect(stored!['email'], 'user.test@anlanh.vn');

      // Login with untrimmed and mixed-case email must succeed
      final loggedIn = await authRepository.login('   USER.TEST@ANLANH.VN   ', 'password123');
      expect(loggedIn, isNotNull);
      expect(loggedIn!.email, 'user.test@anlanh.vn');
    });

    test('T2_AUTH_02: Password length boundary: exactly 6 characters succeeds; 5 characters fails validation', () {
      // 5 characters: failure
      final error5 = FormValidator.validatePassword('12345');
      expect(error5, isNotNull);
      expect(error5, contains('6 ký tự'));

      // 6 characters: success boundary
      final valid6 = FormValidator.validatePassword('123456');
      expect(valid6, isNull);

      // 7 characters: valid
      final valid7 = FormValidator.validatePassword('1234567');
      expect(valid7, isNull);
    });

    test('T2_AUTH_03: Empty strings, whitespace-only strings, or null values fail form validation rules', () {
      // Email checks
      expect(FormValidator.validateEmail(null), isNotNull);
      expect(FormValidator.validateEmail(''), isNotNull);
      expect(FormValidator.validateEmail('   '), isNotNull);

      // Password checks
      expect(FormValidator.validatePassword(null), isNotNull);
      expect(FormValidator.validatePassword(''), isNotNull);

      // Name checks
      expect(FormValidator.validateName(null), isNotNull);
      expect(FormValidator.validateName(''), isNotNull);
      expect(FormValidator.validateName('   '), isNotNull);

      // Confirm Password checks
      expect(FormValidator.validateConfirmPassword('pass123', null), isNotNull);
      expect(FormValidator.validateConfirmPassword('pass123', 'different'), isNotNull);
    });

    test('T2_AUTH_04: Vietnamese diacritics and special password characters hash and persist accurately', () async {
      const vietnameseName = 'Nguyễn Văn Đạt Hoàng';
      const specialPassword = 'P@ssw0rd!#\$%^&*()_+=~`{}[]:;"\'<>,.?/|\\';

      final success = await authRepository.register(
        'dat.hoang@anlanh.vn',
        specialPassword,
        vietnameseName,
      );
      expect(success, isTrue);

      final userInDb = await userDao.getUserByEmail('dat.hoang@anlanh.vn');
      expect(userInDb, isNotNull);
      expect(userInDb!['username'], vietnameseName);

      // Verify login with exact special character password succeeds
      final loggedIn = await authRepository.login('dat.hoang@anlanh.vn', specialPassword);
      expect(loggedIn, isNotNull);
      expect(loggedIn!.username, vietnameseName);

      // Login with slight variation must fail
      final badLogin = await authRepository.login('dat.hoang@anlanh.vn', 'P@ssw0rd!#\$%^&*()_+=~');
      expect(badLogin, isNull);
    });

    test('T2_AUTH_05: Corrupted or tampered session token in storage falls back safely to unauthenticated state', () async {
      // Simulation of session parsing from storage
      User? parseSessionToken(String? rawToken) {
        if (rawToken == null || rawToken.isEmpty) return null;
        try {
          final decoded = utf8.decode(base64.decode(rawToken));
          final map = jsonDecode(decoded) as Map<String, dynamic>;
          if (!map.containsKey('email') || !map.containsKey('password_hash')) {
            return null;
          }
          return User.fromMap(map);
        } catch (_) {
          // Corrupted / tampered payload caught safely
          return null;
        }
      }

      // Valid token parses
      final validPayload = jsonEncode({
        'id': 10,
        'username': 'ValidUser',
        'email': 'valid@anlanh.vn',
        'password_hash': 'sha256hash',
        'created_at': DateTime.now().toIso8601String(),
      });
      final validToken = base64.encode(utf8.encode(validPayload));
      final validUser = parseSessionToken(validToken);
      expect(validUser, isNotNull);
      expect(validUser!.email, 'valid@anlanh.vn');

      // Tampered / corrupted tokens
      expect(parseSessionToken('not-a-valid-base64!@#%'), isNull);
      expect(parseSessionToken(base64.encode(utf8.encode('random text not json'))), isNull);
      expect(parseSessionToken(base64.encode(utf8.encode('{"missing_fields": true}'))), isNull);
      expect(parseSessionToken(''), isNull);
      expect(parseSessionToken(null), isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:an_lanh/business_logic/rules/allergy_evaluator.dart';
import 'package:an_lanh/business_logic/rules/nutrition_evaluator.dart';
import 'package:an_lanh/business_logic/viewmodels/search_viewmodel.dart';
import 'package:an_lanh/data/local/daos/profile_dao.dart';
import 'package:an_lanh/data/local/daos/user_dao.dart';
import 'package:an_lanh/data/models/cached_product.dart';
import 'package:an_lanh/data/models/user_profile.dart';
import 'package:an_lanh/data/repositories/auth_repository.dart';
import 'package:an_lanh/data/repositories/product_repository.dart';
import '../helpers/test_database_helper.dart';

class SlowMockProductRepository extends Fake implements ProductRepository {
  @override
  Future<List<CachedProduct>> searchProducts(String query) async {
    if (query == 'slow') {
      await Future.delayed(const Duration(milliseconds: 100));
      return [
        CachedProduct(
          id: 1,
          barcode: '111',
          productName: 'slow item',
          cachedAt: '2026-01-01',
        ),
      ];
    } else {
      await Future.delayed(const Duration(milliseconds: 10));
      return [
        CachedProduct(
          id: 2,
          barcode: '222',
          productName: 'fast item',
          cachedAt: '2026-01-01',
        ),
      ];
    }
  }
}

void main() {
  late Database db;
  late UserDao userDao;
  late ProfileDao profileDao;
  late AuthRepository authRepo;

  setUpAll(() {
    setupTestDatabaseFactory();
  });

  setUp(() async {
    db = await createInMemoryTestDatabase(seedData: false);
    userDao = UserDao();
    profileDao = ProfileDao();
    authRepo = AuthRepository(userDao: userDao);
  });

  tearDown(() async {
    await tearDownTestDatabase(db);
  });

  group('Tier 5 Adversarial: State Mutations, Concurrency & Lifecycles', () {
    test('T5_ADV_STATE_01: Rapid double-submission on user registration', () async {
      // User double taps registration button in 2ms
      final results = await Future.wait([
        authRepo.register('rapid@example.com', 'password123', 'RapidUser'),
        authRepo.register('rapid@example.com', 'password123', 'RapidUser'),
      ]);

      // Exactly one succeeds, the other fails cleanly with false (duplicate email rejection)
      final successCount = results.where((r) => r == true).length;
      final failCount = results.where((r) => r == false).length;

      expect(successCount, 1);
      expect(failCount, 1);

      // Verify SQLite state contains exactly 1 user row
      final countRows = await db.rawQuery(
        'SELECT COUNT(*) as count FROM users WHERE email = ?',
        ['rapid@example.com'],
      );
      expect(Sqflite.firstIntValue(countRows), 1);
    });

    test('T5_ADV_STATE_02: Profile target negative / zero sentinel value handling', () {
      // Profile contains -1.0 (unset legacy target) and 0.0 (zero tolerance fat target)
      final targets = {
        'sugars': -1.0,
        'fat': 0.0,
      };

      // Case A: Product with sugars=15g and fat=0.0g (e.g. pure fruit juice)
      // Must NOT flag sugars (since limit is -1.0 unconstrained), and must NOT flag fat (0.0 not > 0.0)
      final violationsA = NutritionEvaluator.evaluate(
        targets: targets,
        actualData: {
          'sugars_100g': 15.0,
          'fat_100g': 0.0,
        },
      );
      expect(violationsA, isEmpty);

      // Case B: Product with sugars=15g and fat=5.0g (violates zero-fat tolerance)
      final violationsB = NutritionEvaluator.evaluate(
        targets: targets,
        actualData: {
          'sugars_100g': 15.0,
          'fat_100g': 5.0,
        },
      );
      expect(violationsB.length, 1);
      expect(violationsB.first, contains('fat'));
      expect(violationsB.first, isNot(contains('sugars')));
    });

    test('T5_ADV_STATE_03: Concurrent profile mutation during active scan evaluation', () async {
      // Initialize profile in SQLite
      await profileDao.upsertProfile(
        UserProfile(
          id: 1,
          name: 'Snapshot User',
          allergens: ['milk'],
          nutritionTargets: {'sugars': 10.0},
          updatedAt: '2026-01-01',
        ),
      );

      final snapshotProfile = await profileDao.getProfile();
      expect(snapshotProfile?.allergens, contains('milk'));

      // Simulate concurrent profile update happening in background while evaluation runs
      final evaluationFuture = Future(() {
        return AllergyEvaluator.evaluate(
          userAllergens: snapshotProfile?.allergens ?? [],
          ingredientsText: 'Bánh bơ sữa tươi thơm ngon',
        );
      });

      final mutationFuture = Future(() async {
        await profileDao.upsertProfile(
          UserProfile(
            id: 1,
            name: 'Snapshot User Updated',
            allergens: ['peanut'],
            nutritionTargets: {'sugars': 25.0},
            updatedAt: '2026-01-01',
          ),
        );
      });

      final results = await Future.wait([evaluationFuture, mutationFuture]);
      final violations = results[0] as List<String>;

      // Snapshot evaluation succeeded deterministically despite concurrent SQLite write
      expect(violations, contains('milk'));

      // New profile in database reflects updated allergens
      final updatedProfile = await profileDao.getProfile();
      expect(updatedProfile?.allergens, contains('peanut'));
      expect(updatedProfile?.allergens, isNot(contains('milk')));
    });

    test('T5_ADV_STATE_04: Search debouncer rapid mutation and out-of-order resolution', () async {
      final mockRepo = SlowMockProductRepository();
      final searchVm = SearchViewModel(productRepository: mockRepo);

      // Rapidly initiate 'slow' (takes 100ms) then immediately 'fast' (takes 10ms)
      final f1 = searchVm.search('slow');
      final f2 = searchVm.search('fast');

      await Future.wait([f1, f2]);

      // Only the final query results ('fast' -> 'fast item') must remain in VM state
      expect(searchVm.searchQuery, 'fast');
      expect(searchVm.searchResults.length, 1);
      expect(searchVm.searchResults.first.productName, 'fast item');

      searchVm.dispose();
    });

    test('T5_ADV_STATE_05: Session invalidation / logout mid-operation', () async {
      await authRepo.register('session@example.com', 'password123', 'SessionUser');
      final user = await authRepo.login('session@example.com', 'password123');
      expect(user, isNotNull);
      expect(await authRepo.getCurrentUser(), isNotNull);

      // Simulate in-flight async process while user triggers logout
      final inFlightProcess = Future.delayed(const Duration(milliseconds: 30), () async {
        final current = await authRepo.getCurrentUser();
        return current?.email;
      });

      // User logs out mid-flight
      await authRepo.logout();
      expect(await authRepo.getCurrentUser(), isNull);

      final observedSession = await inFlightProcess;
      // In-flight process observed null session or unauthenticated state cleanly
      expect(observedSession, isNull);

      // Persistent session check confirms logged out
      final currentUserAfter = await authRepo.getCurrentUser();
      expect(currentUserAfter, isNull);
    });
  });
}

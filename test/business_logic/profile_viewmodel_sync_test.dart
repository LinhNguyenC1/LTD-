import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:an_lanh/business_logic/viewmodels/profile_viewmodel.dart';
import 'package:an_lanh/data/models/user.dart';
import 'package:an_lanh/data/models/user_profile.dart';
import 'package:an_lanh/data/repositories/profile_repository.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
	group('ProfileViewModel - Account Sync & Local Profile Tests', () {
		late MockProfileRepository mockRepo;
		late ProfileViewModel vm;

		setUp(() {
			mockRepo = MockProfileRepository();
			vm = ProfileViewModel(profileRepository: mockRepo);
		});

		tearDown(() {
			vm.dispose();
		});

		test('loadProfile without arguments loads local profile', () async {
			final localProfile = UserProfile(
				id: 1,
				name: 'Khách',
				allergens: ['milk'],
				updatedAt: '2026-01-01',
			);
			when(() => mockRepo.fetchUserProfile()).thenAnswer((_) async => localProfile);

			await vm.loadProfile();

			expect(vm.profile?.id, 1);
			expect(vm.profile?.name, 'Khách');
			expect(vm.isSynced, isFalse);
			verify(() => mockRepo.fetchUserProfile()).called(1);
		});

		test('syncOnLogin copies local profile to user profile when account has no existing profile', () async {
			final user = User(
				id: 2,
				username: 'linh_tran',
				email: 'linh@example.com',
				passwordHash: 'hash',
				createdAt: '2026-01-01',
			);
			final localProfile = UserProfile(
				id: 1,
				name: 'Linh',
				allergens: ['peanut'],
				nutritionTargets: {'sugars': 10.0},
				updatedAt: '2026-01-01',
			);

			final user2Profile = UserProfile(
				id: 2,
				userId: 2,
				name: 'Linh',
				allergens: ['peanut'],
				nutritionTargets: {'sugars': 10.0},
				updatedAt: '2026-01-01',
			);

			var fetchCount = 0;
			// First call returns null (no saved profile yet), second call returns user2Profile
			when(() => mockRepo.fetchUserProfile(2)).thenAnswer((_) async {
				if (fetchCount == 0) {
					fetchCount++;
					return null;
				}
				return user2Profile;
			});
			// Local profile exists
			when(() => mockRepo.fetchUserProfile(null)).thenAnswer((_) async => localProfile);
			// Expect save to user 2
			when(() => mockRepo.saveUserProfile(
				userId: 2,
				name: 'Linh',
				allergens: ['peanut'],
				nutritionTargets: {'sugars': 10.0},
			)).thenAnswer((_) async {});

			await vm.syncOnLogin(user);

			expect(vm.activeUserId, 2);
			expect(vm.isSynced, isTrue);
			expect(vm.profile?.id, 2);
			expect(vm.profile?.name, 'Linh');
			expect(vm.profile?.allergens, contains('peanut'));
		});

		test('syncOnLogin loads existing user profile directly when already present', () async {
			final user = User(
				id: 3,
				username: 'tuan_anh',
				email: 'tuan@example.com',
				passwordHash: 'hash',
				createdAt: '2026-01-01',
			);
			final existingUserProfile = UserProfile(
				id: 3,
				name: 'Tuấn Anh',
				allergens: ['seafood', 'shrimp'],
				nutritionTargets: {'sodium': 0.3},
				updatedAt: '2026-01-02',
			);

			when(() => mockRepo.fetchUserProfile(3)).thenAnswer((_) async => existingUserProfile);

			await vm.syncOnLogin(user);

			expect(vm.activeUserId, 3);
			expect(vm.isSynced, isTrue);
			expect(vm.profile?.name, 'Tuấn Anh');
			expect(vm.profile?.allergens, contains('seafood'));
			verifyNever(() => mockRepo.saveUserProfile(
				userId: any(named: 'userId'),
				name: any(named: 'name'),
				allergens: any(named: 'allergens'),
				nutritionTargets: any(named: 'nutritionTargets'),
			));
		});

		test('onLogout switches activeUserId back to null and reloads local profile', () async {
			final localProfile = UserProfile(
				id: 1,
				name: 'Người dùng máy',
				allergens: [],
				updatedAt: '2026-01-01',
			);
			when(() => mockRepo.fetchUserProfile()).thenAnswer((_) async => localProfile);

			await vm.onLogout();

			expect(vm.activeUserId, isNull);
			expect(vm.isSynced, isFalse);
			expect(vm.profile?.id, 1);
			expect(vm.profile?.name, 'Người dùng máy');
		});

		test('saveProfile saves to active user profile when authenticated', () async {
			final user = User(
				id: 5,
				username: 'mai_hoa',
				email: 'mai@example.com',
				passwordHash: 'hash',
				createdAt: '2026-01-01',
			);
			when(() => mockRepo.fetchUserProfile(5)).thenAnswer((_) async => null);
			when(() => mockRepo.fetchUserProfile()).thenAnswer((_) async => null);
			when(() => mockRepo.saveUserProfile(
				userId: 5,
				name: any(named: 'name'),
				allergens: any(named: 'allergens'),
				nutritionTargets: any(named: 'nutritionTargets'),
			)).thenAnswer((_) async {});

			await vm.syncOnLogin(user);

			final updatedProfile = UserProfile(
				id: 5,
				name: 'Mai Hoa',
				allergens: ['gluten'],
				nutritionTargets: {'sugars': 8.0},
				updatedAt: '2026-01-03',
			);
			when(() => mockRepo.fetchUserProfile(5)).thenAnswer((_) async => updatedProfile);

			final success = await vm.saveProfile(
				name: 'Mai Hoa',
				allergens: ['gluten'],
				nutritionTargets: {'sugars': 8.0},
			);

			expect(success, isTrue);
			verify(() => mockRepo.saveUserProfile(
				userId: 5,
				name: 'Mai Hoa',
				allergens: ['gluten'],
				nutritionTargets: {'sugars': 8.0},
			)).called(1);
			expect(vm.profile?.id, 5);
			expect(vm.profile?.allergens, contains('gluten'));
		});
	});
}

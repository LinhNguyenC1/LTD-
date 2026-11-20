import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:an_lanh/business_logic/viewmodels/auth_viewmodel.dart';
import 'package:an_lanh/business_logic/viewmodels/profile_viewmodel.dart';
import 'package:an_lanh/core/services/notification_service.dart';
import 'package:an_lanh/data/models/user.dart';
import 'package:an_lanh/data/models/user_profile.dart';
import 'package:an_lanh/data/repositories/auth_repository.dart';
import 'package:an_lanh/data/repositories/profile_repository.dart';
import 'package:an_lanh/presentation/screens/profile/profile_page.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockProfileRepository mockProfileRepo;
  late MockAuthRepository mockAuthRepo;
  late ProfileViewModel profileViewModel;
  late AuthViewModel authViewModel;

  setUp(() {
    mockProfileRepo = MockProfileRepository();
    mockAuthRepo = MockAuthRepository();

    when(() => mockAuthRepo.getCurrentUser()).thenAnswer((_) async => null);
    when(() => mockProfileRepo.fetchUserProfile()).thenAnswer((_) async => null);

    profileViewModel = ProfileViewModel(profileRepository: mockProfileRepo);
    authViewModel = AuthViewModel(
      authRepository: mockAuthRepo,
      notificationService: NotificationService.forTest(),
    );
  });

  tearDown(() {
    profileViewModel.dispose();
    authViewModel.dispose();
  });

  Widget buildTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProfileViewModel>.value(value: profileViewModel),
        ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
      ],
      child: const MaterialApp(
        home: ProfilePage(),
      ),
    );
  }

  group('ProfilePage - Rendering and Loaded State', () {
    testWidgets('renders initial default profile components when no profile exists', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Hồ sơ ăn uống'), findsOneWidget);
      expect(find.byKey(const Key('profile_name_field')), findsOneWidget);
      expect(find.byKey(const Key('profile_target_sugars')), findsOneWidget);
      expect(find.byKey(const Key('profile_target_sodium')), findsOneWidget);
      expect(find.byKey(const Key('profile_target_total_fat')), findsOneWidget);
      expect(find.byKey(const Key('profile_target_protein_min')), findsOneWidget);
      expect(find.byKey(const Key('profile_save_button')), findsOneWidget);
      expect(find.text('Xóa hồ sơ'), findsNothing);
    });

    testWidgets('populates fields and checkboxes when user profile already exists', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final loadedProfile = UserProfile(
        id: 1,
        name: 'Trúc Mai',
        allergens: ['milk', 'gluten'],
        nutritionTargets: {
          'sugars': 10.0,
          'sodium': 2.5,
          'total_fat': -1.0,
          'protein_min': 50.0,
        },
        updatedAt: '2026-01-01',
      );
      when(() => mockProfileRepo.fetchUserProfile()).thenAnswer((_) async => loadedProfile);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final nameField = tester.widget<TextFormField>(find.byKey(const Key('profile_name_field')));
      expect(nameField.controller?.text, 'Trúc Mai');

      final sugarsField = tester.widget<TextFormField>(find.byKey(const Key('profile_target_sugars')));
      expect(sugarsField.controller?.text, '10.0');

      final sodiumField = tester.widget<TextFormField>(find.byKey(const Key('profile_target_sodium')));
      expect(sodiumField.controller?.text, '2.5');

      final fatField = tester.widget<TextFormField>(find.byKey(const Key('profile_target_total_fat')));
      expect(fatField.controller?.text, '');

      expect(find.text('Xóa hồ sơ'), findsOneWidget);
    });
  });

  group('ProfilePage - Form Validation Hardening', () {
    testWidgets('shows validation error when name is empty upon submit and blocks submission', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final saveBtn = find.byKey(const Key('profile_save_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Họ tên không được để trống'), findsOneWidget);
      verifyNever(() => mockProfileRepo.saveUserProfile(
        name: any(named: 'name'),
        allergens: any(named: 'allergens'),
        nutritionTargets: any(named: 'nutritionTargets'),
      ));
    });

    testWidgets('shows validation error when name is whitespace-only upon submit', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('profile_name_field')), '   ');

      final saveBtn = find.byKey(const Key('profile_save_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Họ tên không được để trống'), findsOneWidget);
      verifyNever(() => mockProfileRepo.saveUserProfile(
        name: any(named: 'name'),
        allergens: any(named: 'allergens'),
        nutritionTargets: any(named: 'nutritionTargets'),
      ));
    });

    testWidgets('shows validation error when nutritional target is non-numeric upon submit', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('profile_name_field')), 'Linh');
      await tester.enterText(find.byKey(const Key('profile_target_sugars')), 'abc');

      final saveBtn = find.byKey(const Key('profile_save_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập số hợp lệ'), findsOneWidget);
      verifyNever(() => mockProfileRepo.saveUserProfile(
        name: any(named: 'name'),
        allergens: any(named: 'allergens'),
        nutritionTargets: any(named: 'nutritionTargets'),
      ));
    });

    testWidgets('shows validation error when nutritional target is negative upon submit', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('profile_name_field')), 'Linh');
      await tester.enterText(find.byKey(const Key('profile_target_sugars')), '-15');

      final saveBtn = find.byKey(const Key('profile_save_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Giá trị phải lớn hơn 0'), findsOneWidget);
      verifyNever(() => mockProfileRepo.saveUserProfile(
        name: any(named: 'name'),
        allergens: any(named: 'allergens'),
        nutritionTargets: any(named: 'nutritionTargets'),
      ));
    });

    testWidgets('shows validation error when nutritional target is zero upon submit', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('profile_name_field')), 'Linh');
      await tester.enterText(find.byKey(const Key('profile_target_sugars')), '0');

      final saveBtn = find.byKey(const Key('profile_save_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Giá trị phải lớn hơn 0'), findsOneWidget);
      verifyNever(() => mockProfileRepo.saveUserProfile(
        name: any(named: 'name'),
        allergens: any(named: 'allergens'),
        nutritionTargets: any(named: 'nutritionTargets'),
      ));
    });

    testWidgets('shows validation error when nutritional target is NaN upon submit', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('profile_name_field')), 'Linh');
      await tester.enterText(find.byKey(const Key('profile_target_sugars')), 'NaN');

      final saveBtn = find.byKey(const Key('profile_save_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập số hợp lệ'), findsOneWidget);
      verifyNever(() => mockProfileRepo.saveUserProfile(
        name: any(named: 'name'),
        allergens: any(named: 'allergens'),
        nutritionTargets: any(named: 'nutritionTargets'),
      ));
    });

    testWidgets('shows validation error when nutritional target is Infinity upon submit', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('profile_name_field')), 'Linh');
      await tester.enterText(find.byKey(const Key('profile_target_sugars')), 'Infinity');

      final saveBtn = find.byKey(const Key('profile_save_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập số hợp lệ'), findsOneWidget);
      verifyNever(() => mockProfileRepo.saveUserProfile(
        name: any(named: 'name'),
        allergens: any(named: 'allergens'),
        nutritionTargets: any(named: 'nutritionTargets'),
      ));
    });

    testWidgets('shows validation error when nutritional target is +Infinity upon submit', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('profile_name_field')), 'Linh');
      await tester.enterText(find.byKey(const Key('profile_target_sugars')), '+Infinity');

      final saveBtn = find.byKey(const Key('profile_save_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập số hợp lệ'), findsOneWidget);
      verifyNever(() => mockProfileRepo.saveUserProfile(
        name: any(named: 'name'),
        allergens: any(named: 'allergens'),
        nutritionTargets: any(named: 'nutritionTargets'),
      ));
    });

    testWidgets('does not validate disabled nutritional fields when unchecked', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      when(() => mockProfileRepo.saveUserProfile(
        name: any(named: 'name'),
        allergens: any(named: 'allergens'),
        nutritionTargets: any(named: 'nutritionTargets'),
      )).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('profile_name_field')), 'Linh');

      final sugarsCheckbox = find.byWidgetPredicate((widget) =>
        widget is Checkbox && widget.value == true
      ).first;
      await tester.tap(sugarsCheckbox);
      await tester.pumpAndSettle();

      final saveBtn = find.byKey(const Key('profile_save_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      verify(() => mockProfileRepo.saveUserProfile(
        name: 'Linh',
        allergens: any(named: 'allergens'),
        nutritionTargets: any(named: 'nutritionTargets'),
      )).called(1);
    });
  });

  group('ProfilePage - Successful Submission and Persistence', () {
    testWidgets('successful submission when all fields are valid, verifying parsed targets', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      when(() => mockProfileRepo.saveUserProfile(
        name: any(named: 'name'),
        allergens: any(named: 'allergens'),
        nutritionTargets: any(named: 'nutritionTargets'),
      )).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('profile_name_field')), 'Trúc Mai');
      await tester.enterText(find.byKey(const Key('profile_target_sugars')), '15.5');
      await tester.enterText(find.byKey(const Key('profile_target_sodium')), '2.0');
      await tester.enterText(find.byKey(const Key('profile_target_total_fat')), '12,5');

      final saveBtn = find.byKey(const Key('profile_save_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      verify(() => mockProfileRepo.saveUserProfile(
        name: 'Trúc Mai',
        allergens: any(named: 'allergens'),
        nutritionTargets: any(
          named: 'nutritionTargets',
          that: allOf([
            containsPair('sugars', 15.5),
            containsPair('sodium', 2.0),
            containsPair('total_fat', 12.5),
          ]),
        ),
      )).called(1);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Đã lưu hồ sơ vào SQLite thành công!'), findsOneWidget);
    });

    testWidgets('shows error SnackBar when saving profile fails in repository', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      when(() => mockProfileRepo.saveUserProfile(
        name: any(named: 'name'),
        allergens: any(named: 'allergens'),
        nutritionTargets: any(named: 'nutritionTargets'),
      )).thenThrow(Exception('SQLite write error'));

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('profile_name_field')), 'Trúc');

      final saveBtn = find.byKey(const Key('profile_save_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Không thể lưu hồ sơ'), findsOneWidget);
    });
  });

  group('ProfilePage - Deletion and Account Actions', () {
    testWidgets('deletes profile when confirmation dialog is accepted', (tester) async {
      tester.view.physicalSize = const Size(800, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final loadedProfile = UserProfile(
        id: 1,
        name: 'Trúc Mai',
        allergens: ['milk'],
        nutritionTargets: {'sugars': 10.0},
        updatedAt: '2026-01-01',
      );
      when(() => mockProfileRepo.fetchUserProfile()).thenAnswer((_) async => loadedProfile);
      when(() => mockProfileRepo.clearUserProfile()).thenAnswer((_) async {});

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final deleteBtn = find.text('Xóa hồ sơ');
      await tester.ensureVisible(deleteBtn);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.text('Xóa hồ sơ ăn uống?'), findsOneWidget);
      expect(find.text('Xác nhận xóa'), findsOneWidget);

      await tester.tap(find.text('Xác nhận xóa'));
      await tester.pumpAndSettle();

      verify(() => mockProfileRepo.clearUserProfile()).called(1);
      expect(find.text('Đã xóa hồ sơ khỏi cơ sở dữ liệu!'), findsOneWidget);
    });

    testWidgets('canceling deletion dialog does not call clearUserProfile', (tester) async {
      tester.view.physicalSize = const Size(800, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final loadedProfile = UserProfile(
        id: 1,
        name: 'Trúc Mai',
        allergens: ['milk'],
        nutritionTargets: {'sugars': 10.0},
        updatedAt: '2026-01-01',
      );
      when(() => mockProfileRepo.fetchUserProfile()).thenAnswer((_) async => loadedProfile);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final deleteBtn = find.text('Xóa hồ sơ');
      await tester.ensureVisible(deleteBtn);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.text('Hủy'), findsOneWidget);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      verifyNever(() => mockProfileRepo.clearUserProfile());
    });

    testWidgets('account card renders authenticated user details and logout button', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final user = User(
        id: 1,
        username: 'trucmai',
        email: 'truc@example.com',
        passwordHash: 'hash',
        createdAt: '2026-01-01',
      );
      when(() => mockAuthRepo.getCurrentUser()).thenAnswer((_) async => user);
      await authViewModel.loadCurrentUser();

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('trucmai'), findsOneWidget);
      expect(find.text('truc@example.com'), findsOneWidget);
      expect(find.byKey(const Key('profile_logout_button')), findsOneWidget);
    });

    testWidgets('account card renders login button when user is unauthenticated', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_login_button')), findsOneWidget);
    });
  });
}

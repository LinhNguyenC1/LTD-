import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:an_lanh/business_logic/viewmodels/auth_viewmodel.dart';
import 'package:an_lanh/data/models/user.dart';
import 'package:an_lanh/data/repositories/auth_repository.dart';
import 'package:an_lanh/presentation/screens/auth/login_page.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late AuthViewModel authViewModel;

  setUp(() {
    mockRepo = MockAuthRepository();
    authViewModel = AuthViewModel(authRepository: mockRepo);
  });

  Widget buildTestWidget() {
    return ChangeNotifierProvider<AuthViewModel>.value(
      value: authViewModel,
      child: const MaterialApp(
        home: LoginPage(),
      ),
    );
  }

  testWidgets('renders login screen components correctly', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Đăng nhập'), findsNWidgets(2)); // AppBar + Button
    expect(find.byKey(const Key('login_email_field')), findsOneWidget);
    expect(find.byKey(const Key('login_password_field')), findsOneWidget);
    expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
    expect(find.byKey(const Key('navigate_to_register_button')), findsOneWidget);
  });

  testWidgets('shows validation errors when fields are empty', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập email hoặc tên đăng nhập'), findsOneWidget);
    expect(find.text('Mật khẩu không được để trống'), findsOneWidget);
  });

  testWidgets('toggles password visibility', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    final toggleFinder = find.byKey(const Key('login_toggle_password_visibility'));
    expect(toggleFinder, findsOneWidget);

    final passwordFieldFinder = find.byKey(const Key('login_password_field'));
    TextField textField = tester.widget<TextField>(
      find.descendant(of: passwordFieldFinder, matching: find.byType(TextField)),
    );
    expect(textField.obscureText, isTrue);

    await tester.tap(toggleFinder);
    await tester.pumpAndSettle();

    textField = tester.widget<TextField>(
      find.descendant(of: passwordFieldFinder, matching: find.byType(TextField)),
    );
    expect(textField.obscureText, isFalse);
  });

  testWidgets('calls login and handles successful login', (tester) async {
    final user = User(
      id: 1,
      username: 'linh',
      email: 'linh@test.com',
      passwordHash: 'hash',
      createdAt: '2026-01-01',
    );
    when(() => mockRepo.login('linh@test.com', 'password123'))
        .thenAnswer((_) async => user);

    await tester.pumpWidget(buildTestWidget());

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'linh@test.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'password123',
    );

    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Đăng nhập thành công'), findsOneWidget);
  });

  testWidgets('displays error container when login fails', (tester) async {
    when(() => mockRepo.login(any(), any())).thenAnswer((_) async => null);

    await tester.pumpWidget(buildTestWidget());

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'wrong@test.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'password123',
    );

    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Email/tên đăng nhập hoặc mật khẩu không chính xác'), findsOneWidget);
  });

  testWidgets('navigates to RegisterPage when clicking register link', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.byKey(const Key('navigate_to_register_button')));
    await tester.pumpAndSettle();

    expect(find.text('Tạo tài khoản mới 🌱'), findsOneWidget);
  });
}

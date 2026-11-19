import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:an_lanh/business_logic/viewmodels/auth_viewmodel.dart';
import 'package:an_lanh/data/models/user.dart';
import 'package:an_lanh/data/repositories/auth_repository.dart';
import 'package:an_lanh/presentation/screens/auth/register_page.dart';

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
        home: RegisterPage(),
      ),
    );
  }

  testWidgets('renders register screen components correctly', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    expect(find.text('Đăng ký tài khoản'), findsOneWidget);
    expect(find.byKey(const Key('register_name_field')), findsOneWidget);
    expect(find.byKey(const Key('register_email_field')), findsOneWidget);
    expect(find.byKey(const Key('register_password_field')), findsOneWidget);
    expect(find.byKey(const Key('register_confirm_password_field')), findsOneWidget);
    expect(find.byKey(const Key('register_submit_button')), findsOneWidget);
    expect(find.byKey(const Key('navigate_to_login_button')), findsOneWidget);
  });

  testWidgets('shows validation errors when fields are empty', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Họ tên không được để trống'), findsOneWidget);
    expect(find.text('Email không được để trống'), findsOneWidget);
    expect(find.text('Mật khẩu không được để trống'), findsOneWidget);
    expect(find.text('Vui lòng nhập lại mật khẩu'), findsOneWidget);
  });

  testWidgets('validates password mismatch', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    await tester.enterText(
      find.byKey(const Key('register_name_field')),
      'Nguyen Van A',
    );
    await tester.enterText(
      find.byKey(const Key('register_email_field')),
      'test@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('register_password_field')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const Key('register_confirm_password_field')),
      'different456',
    );

    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Mật khẩu xác nhận không khớp'), findsOneWidget);
  });

  testWidgets('validates short password (<6 chars)', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    await tester.enterText(
      find.byKey(const Key('register_name_field')),
      'Nguyen Van A',
    );
    await tester.enterText(
      find.byKey(const Key('register_email_field')),
      'test@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('register_password_field')),
      '12345',
    );
    await tester.enterText(
      find.byKey(const Key('register_confirm_password_field')),
      '12345',
    );

    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Mật khẩu phải có ít nhất 6 ký tự'), findsOneWidget);
  });

  testWidgets('successful registration shows SnackBar', (tester) async {
    final user = User(
      id: 5,
      username: 'Nguyen Van A',
      email: 'test@example.com',
      passwordHash: 'hash',
      createdAt: '2026-01-01',
    );
    when(() => mockRepo.register('test@example.com', 'password123', 'Nguyen Van A'))
        .thenAnswer((_) async => true);
    when(() => mockRepo.getCurrentUser()).thenAnswer((_) async => user);

    await tester.pumpWidget(buildTestWidget());

    await tester.enterText(
      find.byKey(const Key('register_name_field')),
      'Nguyen Van A',
    );
    await tester.enterText(
      find.byKey(const Key('register_email_field')),
      'test@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('register_password_field')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const Key('register_confirm_password_field')),
      'password123',
    );

    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Đăng ký tài khoản thành công'), findsOneWidget);
  });

  testWidgets('displays error container when registration fails in repo', (tester) async {
    when(() => mockRepo.register(any(), any(), any()))
        .thenAnswer((_) async => false);

    await tester.pumpWidget(buildTestWidget());

    await tester.enterText(
      find.byKey(const Key('register_name_field')),
      'ExistingUser',
    );
    await tester.enterText(
      find.byKey(const Key('register_email_field')),
      'existing@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('register_password_field')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const Key('register_confirm_password_field')),
      'password123',
    );

    await tester.tap(find.byKey(const Key('register_submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Đăng ký thất bại. Email hoặc tên tài khoản có thể đã được sử dụng'), findsOneWidget);
  });
}

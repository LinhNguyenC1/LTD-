import 'package:flutter_test/flutter_test.dart';
import 'package:an_lanh/main.dart';
import 'helpers/test_database_helper.dart';

void main() {
  setUpAll(() {
    setupTestDatabaseFactory();
  });

  setUp(() async {
    await createInMemoryTestDatabase(seedData: true);
  });

  testWidgets('renders home screen', (tester) async {
    await tester.pumpWidget(const AnLanhApp());
    await tester.pumpAndSettle();
    expect(find.textContaining('Hiểu nhãn.'), findsOneWidget);
    expect(find.text('Quét mã vạch'), findsOneWidget);
  });
}

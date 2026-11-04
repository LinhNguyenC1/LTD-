import 'package:flutter_test/flutter_test.dart';
import 'package:an_lanh/main.dart';

void main() {
  testWidgets('renders home screen', (tester) async {
    await tester.pumpWidget(const AnLanhApp());
    expect(find.textContaining('Hiểu nhãn.'), findsOneWidget);
    expect(find.text('Quét mã vạch'), findsOneWidget);
  });
}

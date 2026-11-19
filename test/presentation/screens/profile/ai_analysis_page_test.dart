import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:an_lanh/presentation/screens/profile/ai_analysis_page.dart';

void main() {
	group('AiAnalysisPage Widget Tests', () {
		testWidgets('renders extracted allergen criterion accurately', (tester) async {
			tester.view.physicalSize = const Size(800, 1600);
			tester.view.devicePixelRatio = 1.0;
			addTearDown(() {
				tester.view.resetPhysicalSize();
				tester.view.resetDevicePixelRatio();
			});

			await tester.pumpWidget(
				const MaterialApp(
					home: AiAnalysisPage(
						noteText: 'Tôi dị ứng đậu phộng',
						profileName: 'Minh',
					),
				),
			);
			await tester.pumpAndSettle();

			expect(find.text('Bạn chọn, AI gợi ý'), findsOneWidget);
			expect(find.text('Hồ sơ của Minh · Chờ xác nhận áp dụng'), findsOneWidget);
			expect(find.text('Dị ứng đậu phộng'), findsOneWidget);
			expect(find.text('Dị ứng sữa'), findsNothing);
			expect(find.text('Hạn chế đường'), findsNothing);
			expect(find.text('1 mục'), findsOneWidget);
		});

		testWidgets('toggles criterion selection and returns selected map', (tester) async {
			tester.view.physicalSize = const Size(800, 1600);
			tester.view.devicePixelRatio = 1.0;
			addTearDown(() {
				tester.view.resetPhysicalSize();
				tester.view.resetDevicePixelRatio();
			});

			Map<String, dynamic>? returnResult;

			await tester.pumpWidget(
				MaterialApp(
					home: Builder(
						builder: (context) {
							return Scaffold(
								body: ElevatedButton(
									onPressed: () async {
										final res = await Navigator.push<dynamic>(
											context,
											MaterialPageRoute(
												builder: (_) => const AiAnalysisPage(
													noteText: 'Dị ứng sữa và giảm đường',
													profileName: 'Lan',
												),
											),
										);
										if (res is Map<String, dynamic>) {
											returnResult = res;
										}
									},
									child: const Text('Open AI Page'),
								),
							);
						},
					),
				),
			);

			await tester.tap(find.text('Open AI Page'));
			await tester.pumpAndSettle();

			expect(find.text('Dị ứng sữa'), findsOneWidget);
			expect(find.text('Hạn chế đường'), findsOneWidget);
			expect(find.text('2 mục'), findsOneWidget);

			// Uncheck 'Dị ứng sữa'
			final checkboxes = find.byType(Checkbox);
			expect(checkboxes, findsNWidgets(2));
			await tester.tap(checkboxes.first);
			await tester.pumpAndSettle();

			expect(find.text('1 mục'), findsOneWidget);

			// Tap confirm button
			await tester.tap(find.text('Xác nhận áp dụng 1 mục đã chọn'));
			await tester.pumpAndSettle();

			expect(returnResult, isNotNull);
			expect(returnResult!['allergens'], isEmpty);
			expect(returnResult!['nutrition'], contains('sugars'));
			expect(returnResult!['count'], 1);
		});
	});
}

import 'package:flutter/material.dart';
import '../../../business_logic/rules/ai_note_parser.dart';
import '../../../core/theme/app_theme.dart';

class AiAnalysisPage extends StatefulWidget {
	const AiAnalysisPage({
		super.key,
		required this.noteText,
		this.profileName = 'bạn',
	});

	final String noteText;
	final String profileName;

	@override
	State<AiAnalysisPage> createState() => _AiAnalysisPageState();
}

class _AiAnalysisPageState extends State<AiAnalysisPage> {
	late List<ExtractedCriterion> _criteria;

	@override
	void initState() {
		super.initState();
		_criteria = AiNoteParser.parse(widget.noteText);
	}

	@override
	Widget build(BuildContext context) {
		final int selectedCount = _criteria.where((c) => c.isSelected).length;
		final hasNutrition = _criteria.any((c) => c.isSelected && c.type == 'nutrition');
		final hasAllergen = _criteria.any((c) => c.isSelected && c.type == 'allergen');

		return Scaffold(
			appBar: AppBar(
				title: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						const Text(
							'Bạn chọn, AI gợi ý',
							style: TextStyle(
								fontWeight: FontWeight.bold,
								fontSize: 18,
								color: inkText,
							),
						),
						Text(
							'Hồ sơ của ${widget.profileName} · Chờ xác nhận áp dụng',
							style: const TextStyle(fontSize: 12, color: subText),
						),
					],
				),
				backgroundColor: canvasBg,
				elevation: 0,
			),
			body: ListView(
				padding: const EdgeInsets.all(20),
				children: [
					// Badge
					Row(
						children: [
							Container(
								padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
								decoration: BoxDecoration(
									color: const Color(0xFFE4F1E5),
									borderRadius: BorderRadius.circular(16),
								),
								child: const Row(
									mainAxisSize: MainAxisSize.min,
									children: [
										Icon(Icons.check_circle_outline, size: 14, color: primaryGreen),
										SizedBox(width: 4),
										Text(
											'Đã nhận gợi ý',
											style: TextStyle(
												color: primaryGreen,
												fontSize: 12,
												fontWeight: FontWeight.bold,
											),
										),
									],
								),
							),
						],
					),
					const SizedBox(height: 12),
					const Text(
						'Xem lại những điều AI hiểu từ ghi chú. Chỉ áp dụng các mục bạn đồng ý; hồ sơ chưa thay đổi.',
						style: TextStyle(fontSize: 13, color: inkText, height: 1.4),
					),
					const SizedBox(height: 16),

					// User's Note Card
					Card(
						elevation: 0,
						color: Colors.white,
						shape: RoundedRectangleBorder(
							borderRadius: BorderRadius.circular(18),
							side: const BorderSide(color: cardBorder),
						),
						child: Padding(
							padding: const EdgeInsets.all(16),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									const Text(
										'Ghi chú của bạn',
										style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
									),
									const SizedBox(height: 10),
									Container(
										width: double.infinity,
										padding: const EdgeInsets.all(14),
										decoration: BoxDecoration(
											color: const Color(0xFFFAFBF9),
											borderRadius: BorderRadius.circular(14),
											border: Border.all(color: cardBorder),
										),
										child: Text(
											widget.noteText.isNotEmpty
													? widget.noteText
													: 'Tôi dị ứng sữa và đậu phộng, muốn giảm đường và muối',
											style: const TextStyle(
												fontSize: 13,
												color: inkText,
												height: 1.4,
											),
										),
									),
								],
							),
						),
					),
					const SizedBox(height: 14),

					// Permission Banner Box
					Container(
						padding: const EdgeInsets.all(14),
						decoration: BoxDecoration(
							color: const Color(0xFFE8F2E7),
							borderRadius: BorderRadius.circular(16),
						),
						child: const Row(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Icon(Icons.check_circle_outline, color: primaryGreen, size: 20),
								SizedBox(width: 10),
								Expanded(
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Text(
												'Đã cho phép xử lý ghi chú lần này',
												style: TextStyle(
													fontWeight: FontWeight.bold,
													fontSize: 13,
													color: primaryGreen,
												),
											),
											SizedBox(height: 4),
											Text(
												'Ghi chú đã được gửi cho dịch vụ AI sau khi bạn đồng ý. Quyền này chỉ dành cho lần gửi vừa rồi, không phải đồng ý cho mọi lần sau.\n\nMặc định không chia sẻ. Mỗi lần gửi mới đều cần bạn cho phép trước.',
												style: TextStyle(fontSize: 11, color: inkText, height: 1.35),
											),
										],
									),
								),
							],
						),
					),
					const SizedBox(height: 20),

					// Section Header: Tiêu chí bạn muốn giữ
					Row(
						mainAxisAlignment: MainAxisAlignment.spaceBetween,
						children: [
							const Text(
								'Tiêu chí bạn muốn giữ',
								style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
							),
							Text(
								'$selectedCount mục',
								style: const TextStyle(fontSize: 12, color: subText),
							),
						],
					),
					const SizedBox(height: 12),

					// Extracted Criteria Card List
					Card(
						elevation: 0,
						color: Colors.white,
						shape: RoundedRectangleBorder(
							borderRadius: BorderRadius.circular(20),
							side: const BorderSide(color: cardBorder),
						),
						child: Padding(
							padding: const EdgeInsets.all(16),
							child: _criteria.isEmpty
									? const Center(
											child: Padding(
												padding: EdgeInsets.all(16),
												child: Text(
													'Không tìm thấy tiêu chí phù hợp từ ghi chú. Bạn có thể tự thêm mục trong Hồ sơ.',
													textAlign: TextAlign.center,
													style: TextStyle(color: subText, fontSize: 13),
												),
											),
										)
									: ListView.separated(
											shrinkWrap: true,
											physics: const NeverScrollableScrollPhysics(),
											itemCount: _criteria.length,
											separatorBuilder: (_, __) => const Divider(height: 20),
											itemBuilder: (ctx, index) {
												final item = _criteria[index];
												return _buildCriteriaCheckRow(
													title: item.title,
													subtitle: item.subtitle,
													quote: '“${item.quote}”',
													value: item.isSelected,
													onChanged: (v) {
														setState(() {
															item.isSelected = v ?? false;
														});
													},
												);
											},
										),
						),
					),
					const SizedBox(height: 14),

					// Dynamic Notice Card 1
					if (hasNutrition)
						Container(
							padding: const EdgeInsets.all(14),
							margin: const EdgeInsets.only(bottom: 10),
							decoration: BoxDecoration(
								color: const Color(0xFFEAF0F6),
								borderRadius: BorderRadius.circular(16),
							),
							child: const Row(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Icon(Icons.help_outline, color: Color(0xFF385570), size: 18),
									SizedBox(width: 8),
									Expanded(
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: [
												Text(
													'Mức cá nhân do bạn chọn',
													style: TextStyle(
														fontWeight: FontWeight.bold,
														fontSize: 12,
														color: Color(0xFF2C4359),
													),
												),
												SizedBox(height: 2),
												Text(
													'AI đề xuất các chỉ số dinh dưỡng dựa trên ghi chú của bạn. AI không tự ý đặt mức mới nếu không phù hợp và đây không phải là chỉ định y khoa.',
													style: TextStyle(
														fontSize: 11,
														color: Color(0xFF2C4359),
														height: 1.35,
													),
												),
											],
										),
									),
								],
							),
						),

					// Dynamic Notice Card 2
					if (hasAllergen)
						Container(
							padding: const EdgeInsets.all(14),
							margin: const EdgeInsets.only(bottom: 10),
							decoration: BoxDecoration(
								color: const Color(0xFFFFF8EA),
								borderRadius: BorderRadius.circular(16),
							),
							child: const Row(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Icon(
										Icons.warning_amber_rounded,
										color: Color(0xFF8C600F),
										size: 18,
									),
									SizedBox(width: 8),
									Expanded(
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: [
												Text(
													'Dị ứng luôn được ưu tiên cao nhất',
													style: TextStyle(
														fontWeight: FontWeight.bold,
														fontSize: 12,
														color: Color(0xFF6E4B0B),
													),
												),
												SizedBox(height: 2),
												Text(
													'Khi quét thực phẩm, ứng dụng sẽ đối chiếu danh sách dị ứng đã chọn để cảnh báo nguy cơ ngay lập tức.',
													style: TextStyle(
														fontSize: 11,
														color: Color(0xFF6E4B0B),
														height: 1.35,
													),
												),
											],
										),
									),
								],
							),
						),

					const Text(
						'Bạn có thể chỉnh sửa thêm hoặc loại bỏ các lựa chọn này bất kỳ lúc nào trong Hồ sơ.',
						style: TextStyle(fontSize: 11, color: subText),
					),
					const SizedBox(height: 20),

					// Bottom Action Button
					FilledButton.icon(
						onPressed: () {
							final selectedItems = _criteria.where((c) => c.isSelected).toList();
							final selectedAllergens = selectedItems
									.where((c) => c.type == 'allergen' && c.allergenKey != null)
									.map((c) => c.allergenKey!)
									.toList();
							final nutritionMap = <String, double>{};
							for (final c in selectedItems.where(
								(c) => c.type == 'nutrition' && c.nutritionKey != null,
							)) {
								nutritionMap[c.nutritionKey!] = c.targetValue ?? 0.0;
							}
							final selectedDiets = selectedItems
									.where((c) => c.type == 'diet')
									.map((c) => c.id)
									.toList();

							Navigator.pop(context, {
								'allergens': selectedAllergens,
								'nutrition': nutritionMap,
								'diets': selectedDiets,
								'count': selectedItems.length,
								// Legacy backward compatibility flags
								'milk': selectedAllergens.contains('milk'),
								'peanut': selectedAllergens.contains('peanut'),
								'sugar': nutritionMap.containsKey('sugars'),
								'salt': nutritionMap.containsKey('sodium'),
							});
						},
						icon: const Icon(Icons.check),
						label: Text(
							'Xác nhận áp dụng $selectedCount mục đã chọn',
							style: const TextStyle(fontWeight: FontWeight.bold),
						),
						style: FilledButton.styleFrom(
							backgroundColor: primaryGreen,
							minimumSize: const Size.fromHeight(52),
							shape: RoundedRectangleBorder(
								borderRadius: BorderRadius.circular(14),
							),
						),
					),
					const SizedBox(height: 10),

					const Text(
						'Chưa áp dụng · Hồ sơ chỉ thay đổi sau khi bạn xác nhận.',
						textAlign: TextAlign.center,
						style: TextStyle(fontSize: 11, color: subText),
					),
				],
			),
		);
	}

	Widget _buildCriteriaCheckRow({
		required String title,
		required String subtitle,
		required String quote,
		required bool value,
		required ValueChanged<bool?> onChanged,
	}) {
		return Row(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				SizedBox(
					width: 24,
					height: 24,
					child: Checkbox(
						value: value,
						onChanged: onChanged,
						activeColor: primaryGreen,
						shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
					),
				),
				const SizedBox(width: 12),
				Expanded(
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text(
								title,
								style: const TextStyle(
									fontWeight: FontWeight.bold,
									fontSize: 14,
									color: inkText,
								),
							),
							Text(subtitle, style: const TextStyle(fontSize: 11, color: subText)),
							const SizedBox(height: 4),
							Row(
								children: [
									const Text(
										'Từ ghi chú: ',
										style: TextStyle(fontSize: 11, color: subText),
									),
									Expanded(
										child: Text(
											quote,
											style: const TextStyle(
												fontSize: 11,
												fontWeight: FontWeight.bold,
												color: primaryGreen,
											),
										),
									),
								],
							),
						],
					),
				)
			],
		);
	}
}

import 'package:flutter/material.dart';
import '../../../business_logic/rules/ai_note_parser.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/theme/app_theme.dart';

class AiAnalysisPage extends StatefulWidget {
	const AiAnalysisPage({
		super.key,
		required this.noteText,
		this.aiConsent = true,
		this.profileName = 'bạn',
	});

	final String noteText;
	final bool aiConsent;
	final String profileName;

	@override
	State<AiAnalysisPage> createState() => _AiAnalysisPageState();
}

class _AiAnalysisPageState extends State<AiAnalysisPage> {
	late List<ExtractedCriterion> _criteria;
	bool _isFromCloud = false;
	String _providerName = 'Phân tích tự động (Offline)';
	bool _isAnalyzing = false;

	@override
	void initState() {
		super.initState();
		_criteria = AiNoteParser.parse(widget.noteText);
		if (widget.aiConsent && AiService.activeApiKey.isNotEmpty) {
			_runCloudAnalysis();
		}
	}

	Future<void> _runCloudAnalysis() async {
		setState(() => _isAnalyzing = true);
		try {
			final res = await AiService.analyzeNote(
				widget.noteText,
				aiConsent: widget.aiConsent,
			);
			if (mounted && res.criteria.isNotEmpty) {
				setState(() {
					_criteria = res.criteria;
					_isFromCloud = res.isFromCloudAi;
					_providerName = res.providerName;
				});
			}
		} finally {
			if (mounted) {
				setState(() => _isAnalyzing = false);
			}
		}
	}

	void _openApiKeyDialog() async {
		final controller = TextEditingController(text: AiService.activeApiKey);
		final saved = await showDialog<bool>(
			context: context,
			builder: (ctx) => AlertDialog(
				title: const Row(
					children: [
						Icon(Icons.auto_awesome, color: primaryGreen, size: 22),
						SizedBox(width: 8),
						Text('Gemini AI Key', style: TextStyle(fontSize: 16)),
					],
				),
				content: Column(
					mainAxisSize: MainAxisSize.min,
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						const Text(
							'Nhập Google Gemini API Key miễn phí (từ aistudio.google.com) để phân tích ngôn ngữ bằng AI đám mây:',
							style: TextStyle(fontSize: 13, color: subText),
						),
						const SizedBox(height: 12),
						TextField(
							controller: controller,
							decoration: const InputDecoration(
								hintText: 'AIzaSy...',
								border: OutlineInputBorder(),
								contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
							),
						),
					],
				),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(ctx, false),
						child: const Text('Đóng'),
					),
					ElevatedButton(
						style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
						onPressed: () {
							AiService.userApiKey = controller.text.trim();
							Navigator.pop(ctx, true);
						},
						child: const Text('Lưu & Phân tích', style: TextStyle(color: Colors.white)),
					),
				],
			),
		);

		if (saved == true && mounted) {
			await _runCloudAnalysis();
		}
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
							'Gợi ý tiêu chí từ ghi chú',
							style: TextStyle(
								fontWeight: FontWeight.bold,
								fontSize: 17,
								color: inkText,
							),
						),
						Text(
							'Hồ sơ của ${widget.profileName} · Chờ xác nhận áp dụng',
							style: const TextStyle(fontSize: 12, color: subText),
						),
					],
				),
				actions: [
					IconButton(
						icon: Icon(
							_isFromCloud ? Icons.auto_awesome : Icons.key_outlined,
							color: _isFromCloud ? primaryGreen : subText,
						),
						tooltip: 'Cấu hình Gemini API Key',
						onPressed: _openApiKeyDialog,
					),
				],
				backgroundColor: canvasBg,
				elevation: 0,
			),
			body: ListView(
				padding: const EdgeInsets.all(20),
				children: [
					// Source Badge
					Row(
						children: [
							Container(
								padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
								decoration: BoxDecoration(
									color: _isFromCloud ? const Color(0xFFE4F1E5) : const Color(0xFFF0F4F1),
									borderRadius: BorderRadius.circular(16),
								),
								child: Row(
									mainAxisSize: MainAxisSize.min,
									children: [
										if (_isAnalyzing)
											const SizedBox(
												width: 12,
												height: 12,
												child: CircularProgressIndicator(strokeWidth: 2, color: primaryGreen),
											)
										else
											Icon(
												_isFromCloud ? Icons.auto_awesome : Icons.bolt_rounded,
												size: 14,
												color: _isFromCloud ? primaryGreen : subText,
											),
										const SizedBox(width: 5),
										Text(
											_isAnalyzing ? 'Đang phân tích qua AI...' : _providerName,
											style: TextStyle(
												color: _isFromCloud ? primaryGreen : inkText,
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
						'Xem lại những điều hệ thống phân tích từ ghi chú. Chỉ áp dụng các mục bạn đồng ý; hồ sơ chưa thay đổi.',
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

					// Privacy / Source Notice Box
					Container(
						padding: const EdgeInsets.all(14),
						decoration: BoxDecoration(
							color: const Color(0xFFE8F2E7),
							borderRadius: BorderRadius.circular(16),
						),
						child: Row(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								const Icon(Icons.security_outlined, color: primaryGreen, size: 20),
								const SizedBox(width: 10),
								Expanded(
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											const Text(
												'Phân tích thông minh & Tôn trọng quyền riêng tư',
												style: TextStyle(
													fontWeight: FontWeight.bold,
													fontSize: 13,
													color: primaryGreen,
												),
											),
											const SizedBox(height: 4),
											Text(
												_isFromCloud
													? 'Ghi chú được phân tích qua Google Gemini AI an toàn. Dữ liệu được gửi có sự đồng ý của bạn.'
													: widget.aiConsent
														? 'Ghi chú được phân tích hoàn toàn cục bộ trên thiết bị (Offline).'
														: 'Chưa cấp quyền gửi dữ liệu cho AI đám mây. Ghi chú được phân tích hoàn toàn cục bộ trên thiết bị.',
												style: const TextStyle(fontSize: 11, color: inkText, height: 1.35),
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
													'Hệ thống đề xuất các chỉ số dinh dưỡng dựa trên ghi chú của bạn. Đây là tiêu chuẩn cá nhân hóa, không phải chỉ định y khoa.',
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
							final allergenDetails = selectedItems
									.where((c) => c.type == 'allergen' && c.allergenKey != null)
									.map((c) => {'key': c.allergenKey!, 'title': c.title})
									.toList();
							final nutritionMap = <String, double>{};
							final nutritionDetails = <Map<String, dynamic>>[];
							for (final c in selectedItems.where(
								(c) => c.type == 'nutrition' && c.nutritionKey != null,
							)) {
								final val = c.targetValue ?? 0.0;
								nutritionMap[c.nutritionKey!] = val;
								nutritionDetails.add({'key': c.nutritionKey!, 'title': c.title, 'value': val});
							}

							Navigator.pop(context, {
								'allergens': selectedAllergens,
								'allergenDetails': allergenDetails,
								'nutrition': nutritionMap,
								'nutritionDetails': nutritionDetails,
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

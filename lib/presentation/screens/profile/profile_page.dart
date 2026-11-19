import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../business_logic/viewmodels/auth_viewmodel.dart';
import '../../../business_logic/viewmodels/profile_viewmodel.dart';
import '../../../core/validators/form_validator.dart';
import '../auth/login_page.dart';
import 'ai_analysis_page.dart';

class ProfilePage extends StatefulWidget {
	const ProfilePage({super.key});

	@override
	State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
	static const Color _primaryGreen = Color(0xFF286549);
	static const Color _softGreenBg = Color(0xFFEAF2EE);
	static const Color _warmBg = Color(0xFFF8F7F2);
	static const Color _inkText = Color(0xFF203831);
	static const Color _subText = Color(0xFF66756D);
	static const Color _dangerRed = Color(0xFFA34035);

	static const List<Map<String, String>> _allAllergenSuggestions = [
		{'key': 'milk', 'name': 'Sữa (Lactose / Bột sữa)', 'kw': 'sua lactose bo sua dairy'},
		{'key': 'peanut', 'name': 'Đậu phộng (Lạc)', 'kw': 'dau phong lac peanut'},
		{'key': 'gluten', 'name': 'Gluten (Lúa mì / Bột mì)', 'kw': 'gluten lua mi bot mi wheat'},
		{'key': 'soy', 'name': 'Đậu nành (Soy / Lecithin)', 'kw': 'dau nanh dau tuong soy lecithin tofu dau hu'},
		{'key': 'egg', 'name': 'Trứng (Lòng trắng, Lòng đỏ)', 'kw': 'trung ga trung vit egg'},
		{'key': 'shrimp', 'name': 'Tôm / Tép', 'kw': 'tom tep shrimp'},
		{'key': 'crab', 'name': 'Cua / Ghẹ', 'kw': 'cua ghe crab'},
		{'key': 'seafood', 'name': 'Hải sản có vỏ (Nghêu, Sò, Ốc, Mực)', 'kw': 'hai san tom cua so oc muc seafood'},
		{'key': 'fish', 'name': 'Cá biển (Cá hồi, Cá ngừ)', 'kw': 'ca ca bien ca hoi ca ngu fish'},
		{'key': 'tree_nuts', 'name': 'Hạt cây (Hạt điều, Hạnh nhân, Óc chó)', 'kw': 'hat dieu hanh nhan oc cho nut'},
		{'key': 'sesame', 'name': 'Mè (Vừng / Dầu mè)', 'kw': 'me vung sesame'},
		{'key': 'celery', 'name': 'Cần tây', 'kw': 'can tay celery'},
		{'key': 'mustard', 'name': 'Mù tạt (Mustard)', 'kw': 'mu tat mustard'},
		{'key': 'sulfite', 'name': 'Sulfite (Chất bảo quản thực phẩm)', 'kw': 'sulfite luu huynh'},
		{'key': 'msg', 'name': 'Bột ngọt (Mì chính / MSG)', 'kw': 'bot ngot mi chinh msg ajinomoto'},
		{'key': 'corn', 'name': 'Bắp (Ngô / Tinh bột bắp)', 'kw': 'bap ngo corn maize'},
		{'key': 'yeast', 'name': 'Men (Men bánh mì, Men bia)', 'kw': 'men bia banh mi yeast'},
		{'key': 'chili', 'name': 'Ớt / Capsaicin', 'kw': 'ot cay capsaicin chili'},
		{'key': 'beef', 'name': 'Thịt bò (Alpha-gal)', 'kw': 'thit bo beef'},
		{'key': 'chocolate', 'name': 'Cacao / Sô-cô-la', 'kw': 'cacao chocolate so co la'},
	];

	static const List<Map<String, String>> _allNutritionSuggestions = [
		{'key': 'sugars', 'name': 'Đường tối đa (g / 100g)', 'kw': 'duong duong tinh luyen sugar ngot do ngot'},
		{'key': 'sodium', 'name': 'Muối / Natri tối đa (g / 100g)', 'kw': 'muoi natri sodium salt man'},
		{'key': 'total_fat', 'name': 'Chất béo tổng tối đa (g / 100g)', 'kw': 'chat beo tong fat lipid mo dau'},
		{'key': 'protein_min', 'name': 'Đạm tối thiểu (g / 100g)', 'kw': 'dam protein chat dam thit ca'},
		{'key': 'calories', 'name': 'Năng lượng / Calo tối đa (kcal / 100g)', 'kw': 'nang luong calo calorie kcal energy'},
		{'key': 'fiber', 'name': 'Chất xơ tối thiểu (g / 100g)', 'kw': 'chat xo fiber xo rau cu'},
		{'key': 'carbs', 'name': 'Carbohydrate / Tinh bột (g / 100g)', 'kw': 'carbohydrate tinh bot carb com gao banh'},
		{'key': 'sat_fat', 'name': 'Chất béo bão hòa tối đa (g / 100g)', 'kw': 'chat beo bao hoa saturated fat'},
		{'key': 'trans_fat', 'name': 'Chất béo chuyển hóa / Trans fat (g / 100g)', 'kw': 'chat beo chuyen hoa trans fat beo xau'},
		{'key': 'cholesterol', 'name': 'Cholesterol tối đa (mg / 100g)', 'kw': 'cholesterol mo mau tim mach'},
		{'key': 'calcium', 'name': 'Canxi tối thiểu (mg / 100g)', 'kw': 'canxi calcium xuong'},
		{'key': 'iron', 'name': 'Sắt tối thiểu (mg / 100g)', 'kw': 'sat iron bo mau'},
		{'key': 'potassium', 'name': 'Kali (mg / 100g)', 'kw': 'kali potassium'},
		{'key': 'vitamin_c', 'name': 'Vitamin C tối thiểu (mg / 100g)', 'kw': 'vitamin c de khang cam'},
	];

	final _formKey = GlobalKey<FormState>();
	final TextEditingController _nameController = TextEditingController();
	final TextEditingController _allergenSearchController = TextEditingController();
	final TextEditingController _nutritionSearchController = TextEditingController();

	final Map<String, String> _allergyLabels = {
		'milk': 'Sữa (Lactose / Bột sữa)',
		'peanut': 'Đậu phộng (Lạc)',
		'gluten': 'Gluten (Lúa mì)',
		'soy': 'Đậu nành (Soy / Lecithin)',
	};
	final Set<String> _selectedAllergens = {};
	bool _isAddingAllergen = false;

	final Map<String, String> _nutritionLabels = {
		'sugars': 'Đường tối đa (g / 100g)',
		'sodium': 'Muối / Natri tối đa (g / 100g)',
		'total_fat': 'Chất béo tổng tối đa (g / 100g)',
		'protein_min': 'Đạm tối thiểu (g / 100g)',
	};
	final Map<String, TextEditingController> _nutritionControllers = {
		'sugars': TextEditingController(),
		'sodium': TextEditingController(),
		'total_fat': TextEditingController(),
		'protein_min': TextEditingController(),
	};
	final Set<String> _selectedNutrition = {'sugars', 'sodium', 'total_fat', 'protein_min'};
	bool _isAddingNutrition = false;

	@override
	void initState() {
		super.initState();
		WidgetsBinding.instance.addPostFrameCallback((_) async {
			final vm = context.read<ProfileViewModel>();
			await vm.loadProfile();
			_populateFormFromViewModel(vm);
		});
	}

	void _populateFormFromViewModel(ProfileViewModel vm) {
		final profile = vm.profile;
		if(profile==null) return;
		setState(() {
			_nameController.text = profile.name;
			_selectedAllergens
				..clear()
				..addAll(profile.allergens);
			for(final code in profile.allergens) {
				if(!_allergyLabels.containsKey(code)) {
					final found = _allAllergenSuggestions.firstWhere(
						(s) => s['key'] == code,
						orElse: () => {'key': code, 'name': code},
					);
					_allergyLabels[code] = found['name']!;
				}
			}
			_selectedNutrition.clear();
			for(final entry in profile.nutritionTargets.entries) {
				_selectedNutrition.add(entry.key);
				if(!_nutritionLabels.containsKey(entry.key)) {
					final found = _allNutritionSuggestions.firstWhere(
						(s) => s['key'] == entry.key,
						orElse: () => {'key': entry.key, 'name': entry.key},
					);
					_nutritionLabels[entry.key] = found['name']!;
				}
				final c = _nutritionControllers.putIfAbsent(
					entry.key,
					() => TextEditingController(),
				);
				if(entry.value == -1.0) {
					c.text = '';
				} else {
					c.text = entry.value.toString();
				}
			}
		});
	}

	@override
	void dispose() {
		_nameController.dispose();
		_allergenSearchController.dispose();
		_nutritionSearchController.dispose();
		for(final c in _nutritionControllers.values) {
			c.dispose();
		}
		super.dispose();
	}

	void _addAllergen(String key, String name) {
		setState(() {
			_allergyLabels[key] = name;
			_selectedAllergens.add(key);
			_allergenSearchController.clear();
			_isAddingAllergen = false;
		});
	}

	void _addNutrition(String key, String name) {
		setState(() {
			_nutritionLabels[key] = name;
			_nutritionControllers.putIfAbsent(key, () => TextEditingController());
			_selectedNutrition.add(key);
			_nutritionSearchController.clear();
			_isAddingNutrition = false;
		});
	}

	String _normStr(String s) {
		var r = s.toLowerCase();
		r = r.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
		r = r.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
		r = r.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
		r = r.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
		r = r.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
		r = r.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
		r = r.replaceAll(RegExp(r'[đĐ]'), 'd');
		r = r.replaceAll(RegExp(r'[\u0300-\u036f]'), '');
		return r;
	}

	bool _matchQuery(String text, String key, String query, [String? kw]) {
		final q = query.trim().toLowerCase();
		if(q.isEmpty) return true;
		final nq = _normStr(q);
		final nt = _normStr(text);
		final nk = _normStr(key);
		final nkw = kw != null ? _normStr(kw) : '';
		return nt.contains(nq) || nk.contains(nq) || nkw.contains(nq) || text.toLowerCase().contains(q) || key.toLowerCase().contains(q);
	}

	Future<void> _handleSaveProfile() async {
		FocusScope.of(context).unfocus();
		if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
			return;
		}
		final Map<String, double> targets = {};
		for(final key in _selectedNutrition) {
			final controller = _nutritionControllers[key];
			final text = controller?.text.trim().replaceAll(',', '.') ?? '';
			if(text.isNotEmpty) {
				final parsed = double.tryParse(text);
				if(parsed!=null && parsed > 0) {
					targets[key] = parsed;
				}
			}
		}
		final vm = context.read<ProfileViewModel>();
		final success = await vm.saveProfile(
			name: _nameController.text.trim(),
			allergens: _selectedAllergens.toList(),
			nutritionTargets: targets,
		);
		if(!mounted) return;
		ScaffoldMessenger.of(context).showSnackBar(
			SnackBar(
				content: Text(
					success
						? 'Đã lưu hồ sơ vào SQLite thành công!'
						: (vm.errorMessage ?? 'Có lỗi xảy ra khi lưu'),
				),
				backgroundColor: success ? _primaryGreen : _dangerRed,
			),
		);
	}

	Future<void> _handleDeleteProfile() async {
		final confirmed = await showDialog<bool>(
			context: context,
			builder: (ctx) => AlertDialog(
				title: const Text('Xóa hồ sơ ăn uống?'),
				content: const Text(
					'Toàn bộ tiêu chí dị ứng và mục tiêu dinh dưỡng lưu trên máy sẽ bị xóa.',
				),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(ctx, false),
						child: const Text('Hủy'),
					),
					ElevatedButton(
						style: ElevatedButton.styleFrom(backgroundColor: _dangerRed),
						onPressed: () => Navigator.pop(ctx, true),
						child: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
					),
				],
			),
		);
		if(confirmed!=true || !mounted) return;
		final vm = context.read<ProfileViewModel>();
		final success = await vm.deleteProfile();
		if(success && mounted) {
			setState(() {
				_nameController.clear();
				_selectedAllergens.clear();
				_selectedNutrition.clear();
				for(final c in _nutritionControllers.values) {
					c.clear();
				}
			});
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(
					content: Text('Đã xóa hồ sơ khỏi cơ sở dữ liệu!'),
					backgroundColor: _inkText,
				),
			);
		}
	}

	@override
	Widget build(BuildContext context) {
		final vm = context.watch<ProfileViewModel>();

		return Scaffold(
			backgroundColor: _warmBg,
			appBar: AppBar(
				backgroundColor: _warmBg,
				elevation: 0,
				title: const Text(
					'Hồ sơ ăn uống',
					style: TextStyle(
						color: _inkText,
						fontWeight: FontWeight.bold,
						fontSize: 22,
					),
				),
			),
			body: vm.isLoading
				? const Center(child: CircularProgressIndicator(color: _primaryGreen))
				: Form(
					key: _formKey,
					child: ListView(
						padding: const EdgeInsets.all(16),
						children: [
							_buildAccountCard(context),
							const SizedBox(height: 16),
							_buildSectionCard(
								title: 'Tên xưng hô',
								child: TextFormField(
									key: const Key('profile_name_field'),
									controller: _nameController,
									decoration: const InputDecoration(
										hintText: 'Nhập tên của bạn (VD: Trúc, Linh...)',
										border: OutlineInputBorder(),
										contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
									),
									validator: FormValidator.validateName,
								),
							),
							const SizedBox(height: 16),
							_buildAiBannerCard(),
							const SizedBox(height: 16),
							_buildAllergenSection(),
							const SizedBox(height: 16),
							_buildNutritionSection(),
							const SizedBox(height: 24),
							ElevatedButton(
								key: const Key('profile_save_button'),
								style: ElevatedButton.styleFrom(
									backgroundColor: _primaryGreen,
									padding: const EdgeInsets.symmetric(vertical: 14),
									shape: RoundedRectangleBorder(
										borderRadius: BorderRadius.circular(12),
									),
								),
								onPressed: _handleSaveProfile,
								child: const Text(
									'Lưu hồ sơ',
									style: TextStyle(
										color: Colors.white,
										fontSize: 16,
										fontWeight: FontWeight.w600,
									),
								),
							),
							const SizedBox(height: 12),
							if(vm.hasProfile)
								OutlinedButton(
									style: OutlinedButton.styleFrom(
										foregroundColor: _dangerRed,
										side: const BorderSide(color: _dangerRed),
										padding: const EdgeInsets.symmetric(vertical: 14),
										shape: RoundedRectangleBorder(
											borderRadius: BorderRadius.circular(12),
										),
									),
									onPressed: _handleDeleteProfile,
									child: const Text(
										'Xóa hồ sơ',
										style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
									),
								),
						],
					),
				),
		);
	}

	Widget _buildAllergenSection() {
		return _buildSectionCard(
			title: 'Dị ứng thực phẩm',
			subtitle: 'Cảnh báo đỏ tuyệt đối khi phát hiện thành phần',
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					..._allergyLabels.entries.map((entry) {
						final isChecked = _selectedAllergens.contains(entry.key);
						return Padding(
							padding: const EdgeInsets.symmetric(vertical: 2),
							child: Container(
								decoration: BoxDecoration(
									color: isChecked ? _softGreenBg.withValues(alpha: 0.5) : Colors.transparent,
									borderRadius: BorderRadius.circular(10),
								),
								child: Row(
									children: [
										Checkbox(
											value: isChecked,
											activeColor: _primaryGreen,
											onChanged: (val) {
												setState(() {
													if(val==true) {
														_selectedAllergens.add(entry.key);
													} else {
														_selectedAllergens.remove(entry.key);
													}
												});
											},
										),
										Expanded(
											child: GestureDetector(
												behavior: HitTestBehavior.opaque,
												onTap: () {
													setState(() {
														if(isChecked) {
															_selectedAllergens.remove(entry.key);
														} else {
															_selectedAllergens.add(entry.key);
														}
													});
												},
												child: Text(
													entry.value,
													style: TextStyle(
														color: isChecked ? _primaryGreen : _inkText,
														fontSize: 15,
														fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
													),
												),
											),
										),
										IconButton(
											icon: const Icon(Icons.close, size: 18, color: _subText),
											tooltip: 'Bỏ thành phần này',
											onPressed: () {
												setState(() {
													_allergyLabels.remove(entry.key);
													_selectedAllergens.remove(entry.key);
												});
											},
										),
									],
								),
							),
						);
					}),
					const SizedBox(height: 10),
					if(!_isAddingAllergen)
						InkWell(
							onTap: () {
								setState(() {
									_isAddingAllergen = true;
									_allergenSearchController.clear();
								});
							},
							borderRadius: BorderRadius.circular(10),
							child: Container(
								padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
								decoration: BoxDecoration(
									border: Border.all(color: _primaryGreen.withValues(alpha: 0.3)),
									borderRadius: BorderRadius.circular(10),
									color: _softGreenBg.withValues(alpha: 0.4),
								),
								child: const Row(
									mainAxisAlignment: MainAxisAlignment.center,
									children: [
										Icon(Icons.add, color: _primaryGreen, size: 20),
										SizedBox(width: 8),
										Text(
											'Thêm thành phần dị ứng',
											style: TextStyle(
												color: _primaryGreen,
												fontWeight: FontWeight.w600,
												fontSize: 14,
											),
										),
									],
								),
							),
						)
					else
						Container(
							padding: const EdgeInsets.all(12),
							decoration: BoxDecoration(
								color: Colors.white,
								border: Border.all(color: _primaryGreen.withValues(alpha: 0.5)),
								borderRadius: BorderRadius.circular(12),
								boxShadow: [
									BoxShadow(
										color: Colors.black.withValues(alpha: 0.05),
										blurRadius: 6,
										offset: const Offset(0, 2),
									),
								],
							),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Row(
										children: [
											Expanded(
												child: TextField(
													controller: _allergenSearchController,
													autofocus: true,
													decoration: const InputDecoration(
														hintText: 'Gõ tên thành phần dị ứng...',
														isDense: true,
														prefixIcon: Icon(Icons.search, size: 20),
														border: OutlineInputBorder(),
														contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
													),
													onChanged: (_) => setState(() {}),
													onSubmitted: (val) {
														if(val.trim().isNotEmpty) {
															_addAllergen(
																'custom_allg_${DateTime.now().millisecondsSinceEpoch}',
																val.trim(),
															);
														}
													},
												),
											),
											const SizedBox(width: 6),
											IconButton(
												icon: const Icon(Icons.close, color: _subText),
												tooltip: 'Đóng',
												onPressed: () {
													setState(() {
														_isAddingAllergen = false;
														_allergenSearchController.clear();
													});
												},
											),
										],
									),
									Builder(
										builder: (context) {
											final query = _allergenSearchController.text.trim();
											final suggestions = _allAllergenSuggestions.where((item) {
												return _matchQuery(item['name']!, item['key']!, query, item['kw']);
											}).toList();

											return Container(
												constraints: const BoxConstraints(maxHeight: 180),
												margin: const EdgeInsets.only(top: 8),
												decoration: BoxDecoration(
													color: _warmBg,
													borderRadius: BorderRadius.circular(8),
													border: Border.all(color: Colors.black12),
												),
												child: ListView(
													shrinkWrap: true,
													padding: EdgeInsets.zero,
													children: [
														if(query.isNotEmpty &&
																!suggestions.any((s) => _normStr(s['name']!) == _normStr(query)))
															ListTile(
																dense: true,
																leading: const Icon(Icons.add_circle, color: _primaryGreen, size: 20),
																title: Text(
																	'Thêm mới: "${_allergenSearchController.text.trim()}"',
																	style: const TextStyle(
																		color: _primaryGreen,
																		fontWeight: FontWeight.bold,
																		fontSize: 13,
																	),
																),
																onTap: () {
																	final customText = _allergenSearchController.text.trim();
																	_addAllergen(
																		'custom_allg_${DateTime.now().millisecondsSinceEpoch}',
																		customText,
																	);
																},
															),
														...suggestions.map((item) {
															final isAlreadyAdded = _allergyLabels.containsKey(item['key']);
															return ListTile(
																dense: true,
																leading: Icon(
																	isAlreadyAdded ? Icons.check : Icons.add_circle_outline,
																	color: isAlreadyAdded ? _subText : _primaryGreen,
																	size: 20,
																),
																title: Text(
																	item['name']!,
																	style: TextStyle(
																		fontSize: 13,
																		color: isAlreadyAdded ? _subText : _inkText,
																		fontWeight: isAlreadyAdded ? FontWeight.normal : FontWeight.w500,
																	),
																),
																subtitle: isAlreadyAdded
																	? const Text('Đã có trong danh sách',
																			style: TextStyle(fontSize: 11, color: _subText))
																	: null,
																onTap: () {
																	_addAllergen(item['key']!, item['name']!);
																},
															);
														}),
													],
												),
											);
										},
									),
								],
							),
						),
				],
			),
		);
	}

	Widget _buildNutritionSection() {
		return _buildSectionCard(
			title: 'Nhu cầu dinh dưỡng cá nhân',
			subtitle: 'Để trống định lượng = Tùy ý (không quan trọng mức nạp)',
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					..._nutritionLabels.entries.map((entry) {
						final isChecked = _selectedNutrition.contains(entry.key);
						final controller = _nutritionControllers.putIfAbsent(
							entry.key,
							() => TextEditingController(),
						);

						return Container(
							margin: const EdgeInsets.only(bottom: 12),
							padding: const EdgeInsets.all(12),
							decoration: BoxDecoration(
								color: isChecked ? _softGreenBg.withValues(alpha: 0.35) : Colors.grey.shade50,
								borderRadius: BorderRadius.circular(12),
								border: Border.all(
									color: isChecked ? _primaryGreen.withValues(alpha: 0.3) : Colors.black12,
								),
							),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Row(
										children: [
											Checkbox(
												value: isChecked,
												activeColor: _primaryGreen,
												onChanged: (val) {
													setState(() {
														if(val==true) {
															_selectedNutrition.add(entry.key);
														} else {
															_selectedNutrition.remove(entry.key);
														}
													});
												},
											),
											Expanded(
												child: GestureDetector(
													behavior: HitTestBehavior.opaque,
													onTap: () {
														setState(() {
															if(isChecked) {
																_selectedNutrition.remove(entry.key);
															} else {
																_selectedNutrition.add(entry.key);
															}
														});
													},
													child: Text(
														entry.value,
														style: TextStyle(
															color: isChecked ? _primaryGreen : _inkText,
															fontSize: 15,
															fontWeight: isChecked ? FontWeight.w600 : FontWeight.w500,
														),
													),
												),
											),
											IconButton(
												icon: const Icon(Icons.close, size: 18, color: _subText),
												tooltip: 'Bỏ tiêu chí này',
												onPressed: () {
													setState(() {
														_nutritionLabels.remove(entry.key);
														_nutritionControllers[entry.key]?.dispose();
														_nutritionControllers.remove(entry.key);
														_selectedNutrition.remove(entry.key);
													});
												},
											),
										],
									),
									const SizedBox(height: 6),
									TextFormField(
										key: Key('profile_target_${entry.key}'),
										controller: controller,
										enabled: isChecked,
										keyboardType: const TextInputType.numberWithOptions(decimal: true),
										decoration: InputDecoration(
											isDense: true,
											hintText: 'Để trống = Tùy ý (không giới hạn)',
											hintStyle: TextStyle(
												fontSize: 13,
												color: isChecked ? Colors.black38 : Colors.black26,
												fontStyle: FontStyle.italic,
											),
											labelText: 'Mức định lượng',
											labelStyle: TextStyle(
												fontSize: 13,
												color: isChecked ? _primaryGreen : _subText,
											),
											border: const OutlineInputBorder(),
											contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
											filled: !isChecked,
											fillColor: Colors.grey.shade100,
										),
										validator: (val) {
											if (!isChecked) return null;
											return FormValidator.validatePositiveNumber(val, required: false);
										},
										onChanged: (val) {
											if(!isChecked && val.trim().isNotEmpty) {
												setState(() {
													_selectedNutrition.add(entry.key);
												});
											}
										},
									),
								],
							),
						);
					}),
					const SizedBox(height: 4),
					if(!_isAddingNutrition)
						InkWell(
							onTap: () {
								setState(() {
									_isAddingNutrition = true;
									_nutritionSearchController.clear();
								});
							},
							borderRadius: BorderRadius.circular(10),
							child: Container(
								padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
								decoration: BoxDecoration(
									border: Border.all(color: _primaryGreen.withValues(alpha: 0.3)),
									borderRadius: BorderRadius.circular(10),
									color: _softGreenBg.withValues(alpha: 0.4),
								),
								child: const Row(
									mainAxisAlignment: MainAxisAlignment.center,
									children: [
										Icon(Icons.add, color: _primaryGreen, size: 20),
										SizedBox(width: 8),
										Text(
											'Thêm nhu cầu dinh dưỡng',
											style: TextStyle(
												color: _primaryGreen,
												fontWeight: FontWeight.w600,
												fontSize: 14,
											),
										),
									],
								),
							),
						)
					else
						Container(
							padding: const EdgeInsets.all(12),
							decoration: BoxDecoration(
								color: Colors.white,
								border: Border.all(color: _primaryGreen.withValues(alpha: 0.5)),
								borderRadius: BorderRadius.circular(12),
								boxShadow: [
									BoxShadow(
										color: Colors.black.withValues(alpha: 0.05),
										blurRadius: 6,
										offset: const Offset(0, 2),
									),
								],
							),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Row(
										children: [
											Expanded(
												child: TextField(
													controller: _nutritionSearchController,
													autofocus: true,
													decoration: const InputDecoration(
														hintText: 'Gõ tên chất dinh dưỡng...',
														isDense: true,
														prefixIcon: Icon(Icons.search, size: 20),
														border: OutlineInputBorder(),
														contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
													),
													onChanged: (_) => setState(() {}),
													onSubmitted: (val) {
														if(val.trim().isNotEmpty) {
															_addNutrition(
																'custom_nutr_${DateTime.now().millisecondsSinceEpoch}',
																val.trim(),
															);
														}
													},
												),
											),
											const SizedBox(width: 6),
											IconButton(
												icon: const Icon(Icons.close, color: _subText),
												tooltip: 'Đóng',
												onPressed: () {
													setState(() {
														_isAddingNutrition = false;
														_nutritionSearchController.clear();
													});
												},
											),
										],
									),
									Builder(
										builder: (context) {
											final query = _nutritionSearchController.text.trim();
											final suggestions = _allNutritionSuggestions.where((item) {
												return _matchQuery(item['name']!, item['key']!, query, item['kw']);
											}).toList();

											return Container(
												constraints: const BoxConstraints(maxHeight: 180),
												margin: const EdgeInsets.only(top: 8),
												decoration: BoxDecoration(
													color: _warmBg,
													borderRadius: BorderRadius.circular(8),
													border: Border.all(color: Colors.black12),
												),
												child: ListView(
													shrinkWrap: true,
													padding: EdgeInsets.zero,
													children: [
														if(query.isNotEmpty &&
																!suggestions.any((s) => _normStr(s['name']!) == _normStr(query)))
															ListTile(
																dense: true,
																leading: const Icon(Icons.add_circle, color: _primaryGreen, size: 20),
																title: Text(
																	'Thêm mới: "${_nutritionSearchController.text.trim()}"',
																	style: const TextStyle(
																		color: _primaryGreen,
																		fontWeight: FontWeight.bold,
																		fontSize: 13,
																	),
																),
																onTap: () {
																	final customText = _nutritionSearchController.text.trim();
																	_addNutrition(
																		'custom_nutr_${DateTime.now().millisecondsSinceEpoch}',
																		customText,
																	);
																},
															),
														...suggestions.map((item) {
															final isAlreadyAdded = _nutritionLabels.containsKey(item['key']);
															return ListTile(
																dense: true,
																leading: Icon(
																	isAlreadyAdded ? Icons.check : Icons.add_circle_outline,
																	color: isAlreadyAdded ? _subText : _primaryGreen,
																	size: 20,
																),
																title: Text(
																	item['name']!,
																	style: TextStyle(
																		fontSize: 13,
																		color: isAlreadyAdded ? _subText : _inkText,
																		fontWeight: isAlreadyAdded ? FontWeight.normal : FontWeight.w500,
																	),
																),
																subtitle: isAlreadyAdded
																	? const Text('Đã có trong danh sách',
																			style: TextStyle(fontSize: 11, color: _subText))
																	: null,
																onTap: () {
																	_addNutrition(item['key']!, item['name']!);
																},
															);
														}),
													],
												),
											);
										},
									),
								],
							),
						),
				],
			),
		);
	}

	void _openAiSetupDialog() async {
		final noteController = TextEditingController(
			text: 'Tôi dị ứng sữa và đậu phộng, muốn giảm đường và muối',
		);

		final shouldProceed = await showModalBottomSheet<bool>(
			context: context,
			isScrollControlled: true,
			backgroundColor: Colors.transparent,
			builder: (ctx) {
				return Padding(
					padding: EdgeInsets.only(
						bottom: MediaQuery.of(ctx).viewInsets.bottom,
					),
					child: Container(
						padding: const EdgeInsets.all(20),
						decoration: const BoxDecoration(
							color: Colors.white,
							borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
						),
						child: Column(
							mainAxisSize: MainAxisSize.min,
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Row(
									children: [
										Container(
											padding: const EdgeInsets.all(8),
											decoration: BoxDecoration(
												color: _softGreenBg,
												borderRadius: BorderRadius.circular(10),
											),
											child: const Icon(Icons.auto_awesome_rounded, color: _primaryGreen, size: 22),
										),
										const SizedBox(width: 12),
										const Expanded(
											child: Text(
												'Thiết lập nhanh bằng AI',
												style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _inkText),
											),
										),
										IconButton(
											icon: const Icon(Icons.close),
											onPressed: () => Navigator.pop(ctx, false),
										),
									],
								),
								const SizedBox(height: 12),
								const Text(
									'Nhập mô tả thói quen, bệnh lý hoặc sở thích ăn uống của bạn để AI tự động phân tích và gợi ý tiêu chí dinh dưỡng:',
									style: TextStyle(fontSize: 13, color: _subText, height: 1.4),
								),
								const SizedBox(height: 12),
								TextField(
									controller: noteController,
									maxLines: 3,
									decoration: InputDecoration(
										hintText: 'Ví dụ: Tôi dị ứng sữa và đậu phộng, muốn giảm đường và muối...',
										filled: true,
										fillColor: _warmBg,
										border: OutlineInputBorder(
											borderRadius: BorderRadius.circular(12),
											borderSide: const BorderSide(color: Colors.black12),
										),
									),
								),
								const SizedBox(height: 16),
								FilledButton.icon(
									onPressed: () => Navigator.pop(ctx, true),
									icon: const Icon(Icons.auto_awesome_rounded),
									label: const Text('Phân tích bằng AI', style: TextStyle(fontWeight: FontWeight.bold)),
									style: FilledButton.styleFrom(
										backgroundColor: _primaryGreen,
										minimumSize: const Size.fromHeight(48),
										shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
									),
								),
							],
						),
					),
				);
			},
		);

		if(shouldProceed == true && mounted) {
			final result = await Navigator.push<dynamic>(
				context,
				MaterialPageRoute(
					builder: (_) => AiAnalysisPage(
						noteText: noteController.text,
						profileName: _nameController.text.trim().isNotEmpty
							? _nameController.text.trim()
							: 'bạn',
					),
				),
			);

			if(result != null && mounted) {
				int count = 0;
				setState(() {
					if(result is Map) {
						if(result['allergens'] is List) {
							final list = result['allergens'] as List;
							for(final a in list) {
								final code = a.toString();
								_selectedAllergens.add(code);
								if(!_allergyLabels.containsKey(code)) {
									final found = _allAllergenSuggestions.firstWhere(
										(s) => s['key'] == code,
										orElse: () => {'key': code, 'name': code},
									);
									_allergyLabels[code] = found['name']!;
								}
								count++;
							}
						}
						if(result['nutrition'] is Map) {
							final map = result['nutrition'] as Map;
							map.forEach((k, v) {
								final key = k.toString();
								final val = (v as num).toDouble();
								_selectedNutrition.add(key);
								if(!_nutritionLabels.containsKey(key)) {
									final found = _allNutritionSuggestions.firstWhere(
										(s) => s['key'] == key,
										orElse: () => {'key': key, 'name': key},
									);
									_nutritionLabels[key] = found['name']!;
								}
								_nutritionControllers.putIfAbsent(key, () => TextEditingController()).text =
										val.toString();
								count++;
							});
						}
						if(count == 0 && result['count'] is int) {
							count = result['count'] as int;
						}
					} else if(result is int) {
						count = result;
						_selectedAllergens.add('milk');
						_selectedAllergens.add('peanut');
						_selectedNutrition.add('sugars');
						_nutritionControllers.putIfAbsent('sugars', () => TextEditingController()).text = '10';
						_selectedNutrition.add('sodium');
						_nutritionControllers.putIfAbsent('sodium', () => TextEditingController()).text = '0.3';
					}
				});
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(
						content: Text('Đã áp dụng thành công $count tiêu chí từ AI vào hồ sơ!'),
						backgroundColor: _primaryGreen,
					),
				);
			}
		}
	}

	Widget _buildAiBannerCard() {
		return InkWell(
			onTap: _openAiSetupDialog,
			borderRadius: BorderRadius.circular(16),
			child: Container(
				padding: const EdgeInsets.all(16),
				decoration: BoxDecoration(
					color: _softGreenBg,
					borderRadius: BorderRadius.circular(16),
					border: Border.all(color: _primaryGreen.withValues(alpha: 0.25)),
				),
				child: Row(
					children: [
						Container(
							padding: const EdgeInsets.all(10),
							decoration: BoxDecoration(
								color: _primaryGreen,
								borderRadius: BorderRadius.circular(12),
							),
							child: const Icon(
								Icons.auto_awesome_rounded,
								color: Colors.white,
								size: 22,
							),
						),
						const SizedBox(width: 14),
						const Expanded(
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(
										'Thiết lập nhanh bằng AI',
										style: TextStyle(
											color: _inkText,
											fontSize: 16,
											fontWeight: FontWeight.bold,
										),
									),
									SizedBox(height: 3),
									Text(
										'Nhập mô tả thói quen ăn uống để tự động gợi ý tiêu chí dinh dưỡng',
										style: TextStyle(
											color: _subText,
											fontSize: 13,
										),
									),
								],
							),
						),
						const SizedBox(width: 8),
						const Icon(
							Icons.chevron_right_rounded,
							color: _primaryGreen,
						),
					],
				),
			),
		);
	}

	Widget _buildAccountCard(BuildContext context) {
		final authVm = context.watch<AuthViewModel?>();
		final isAuth = authVm?.isAuthenticated ?? false;
		final user = authVm?.currentUser;

		return Container(
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(color: Colors.black12),
			),
			child: isAuth
				? Row(
					children: [
						const CircleAvatar(
							radius: 22,
							backgroundColor: _softGreenBg,
							child: Icon(Icons.person, color: _primaryGreen, size: 26),
						),
						const SizedBox(width: 14),
						Expanded(
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(
										user?.username ?? '',
										style: const TextStyle(
											fontSize: 16,
											fontWeight: FontWeight.bold,
											color: _inkText,
										),
									),
									const SizedBox(height: 2),
									Text(
										user?.email ?? '',
										style: const TextStyle(
											fontSize: 13,
											color: _subText,
										),
									),
								],
							),
						),
						OutlinedButton(
							key: const Key('profile_logout_button'),
							style: OutlinedButton.styleFrom(
								foregroundColor: _dangerRed,
								side: const BorderSide(color: _dangerRed),
								shape: RoundedRectangleBorder(
									borderRadius: BorderRadius.circular(8),
								),
								padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
							),
							onPressed: () async {
								await authVm?.logout();
							},
							child: const Text('Đăng xuất'),
						),
					],
				)
				: Row(
					children: [
						const CircleAvatar(
							radius: 22,
							backgroundColor: Color(0xFFF0F4F1),
							child: Icon(Icons.person_outline, color: _subText, size: 26),
						),
						const SizedBox(width: 14),
						const Expanded(
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(
										'Chưa đăng nhập',
										style: TextStyle(
											fontSize: 15,
											fontWeight: FontWeight.bold,
											color: _inkText,
										),
									),
									SizedBox(height: 2),
									Text(
										'Đăng nhập để đồng bộ tài khoản',
										style: TextStyle(
											fontSize: 12,
											color: _subText,
										),
									),
								],
							),
						),
						ElevatedButton(
							key: const Key('profile_login_button'),
							style: ElevatedButton.styleFrom(
								backgroundColor: _primaryGreen,
								foregroundColor: Colors.white,
								shape: RoundedRectangleBorder(
									borderRadius: BorderRadius.circular(8),
								),
								padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
							),
							onPressed: () {
								Navigator.push(
									context,
									MaterialPageRoute(builder: (_) => const LoginPage()),
								);
							},
							child: const Text('Đăng nhập / Đăng ký'),
						),
					],
				),
		);
	}

	Widget _buildSectionCard({
		required String title,
		String? subtitle,
		required Widget child,
	}) {
		return Container(
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(color: Colors.black12),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						title,
						style: const TextStyle(
							color: _inkText,
							fontSize: 17,
							fontWeight: FontWeight.bold,
						),
					),
					if(subtitle!=null)...[
						const SizedBox(height: 4),
						Text(
							subtitle,
							style: const TextStyle(color: _subText, fontSize: 13),
						),
					],
					const SizedBox(height: 12),
					child,
				],
			),
		);
	}
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../business_logic/viewmodels/profile_viewmodel.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Bảng màu chuẩn theo thiết kế Tuần 2 của nhóm
  static const Color _primaryGreen = Color(0xFF286549);
  static const Color _softGreenBg = Color(0xFFEAF2EE);
  static const Color _warmBg = Color(0xFFF8F7F2);
  static const Color _inkText = Color(0xFF203831);
  static const Color _subText = Color(0xFF66756D);
  static const Color _dangerRed = Color(0xFFA34035);

  final TextEditingController _nameController = TextEditingController();

  // Danh sách chất dị ứng (lưu xuống bảng user_allergen - chuẩn 1NF)
  final Map<String, String> _allergyLabels = {
    'milk': 'Sữa (Lactose / Bột sữa)',
    'peanut': 'Đậu phộng (Lạc)',
    'gluten': 'Gluten (Lúa mì)',
    'soy': 'Đậu nành (Soy / Lecithin)',
  };
  final Set<String> _selectedAllergens = {};

  // Các trường định lượng dinh dưỡng động (lưu dạng JSON vào nutrition_targets)
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

  @override
  void initState() {
    super.initState();
    // 1. READ: Đọc dữ liệu từ SQLite lên giao diện ngay khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<ProfileViewModel>();
      await vm.loadProfile();
      _populateFormFromViewModel(vm);
    });
  }

  void _populateFormFromViewModel(ProfileViewModel vm) {
    final profile = vm.profile;
    if (profile == null) return;

    setState(() {
      _nameController.text = profile.name;

      _selectedAllergens
        ..clear()
        ..addAll(profile.allergens);

      for (final entry in _nutritionControllers.entries) {
        final savedVal = profile.nutritionTargets[entry.key];
        entry.value.text = savedVal != null ? savedVal.toString() : '';
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final c in _nutritionControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // 2. CREATE / UPDATE: Lưu hoặc cập nhật hồ sơ xuống SQLite
  Future<void> _handleSaveProfile() async {
    final Map<String, double> targets = {};
    _nutritionControllers.forEach((key, controller) {
      final text = controller.text.trim().replaceAll(',', '.');
      if (text.isNotEmpty) {
        final parsed = double.tryParse(text);
        if (parsed != null) {
          targets[key] = parsed;
        }
      }
    });

    final vm = context.read<ProfileViewModel>();
    final success = await vm.saveProfile(
      name: _nameController.text,
      allergens: _selectedAllergens.toList(),
      nutritionTargets: targets,
    );

    if (!mounted) return;
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

  // 3. DELETE: Hiển thị hộp thoại xác nhận và xóa hồ sơ
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
            child: const Text('Xác nhận xóa',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final vm = context.read<ProfileViewModel>();
    final success = await vm.deleteProfile();

    if (success && mounted) {
      setState(() {
        _nameController.clear();
        _selectedAllergens.clear();
        for (final c in _nutritionControllers.values) {
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
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Khối 1: Tên xưng hô
                _buildSectionCard(
                  title: 'Tên xưng hô',
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập tên của bạn (VD: Trúc, Linh...)',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Khối 2: Thẻ giao diện AI (Chỉ hiển thị UI, chưa gắn chức năng)
                _buildAiBannerCard(),
                const SizedBox(height: 16),

                // Khối 3: Dị ứng thực phẩm (bảng user_allergen)
                _buildSectionCard(
                  title: 'Dị ứng thực phẩm',
                  subtitle: 'Cảnh báo đỏ tuyệt đối khi phát hiện thành phần',
                  child: Column(
                    children: _allergyLabels.entries.map((entry) {
                      final isChecked = _selectedAllergens.contains(entry.key);
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            if (isChecked) {
                              _selectedAllergens.remove(entry.key);
                            } else {
                              _selectedAllergens.add(entry.key);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(
                                      color: _inkText, fontSize: 15),
                                ),
                              ),
                              Checkbox(
                                value: isChecked,
                                activeColor: _primaryGreen,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedAllergens.add(entry.key);
                                    } else {
                                      _selectedAllergens.remove(entry.key);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Khối 4: Mục tiêu dinh dưỡng định lượng (JSON động)
                _buildSectionCard(
                  title: 'Nhu cầu dinh dưỡng cá nhân',
                  subtitle: 'Để trống nếu không giới hạn chỉ số đó',
                  child: Column(
                    children: _nutritionLabels.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(
                          controller: _nutritionControllers[entry.key],
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: entry.value,
                            hintText: 'VD: 10.0',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Nút Lưu hồ sơ (Create / Update)
                ElevatedButton(
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

                // Nút Xóa hồ sơ (Delete)
                if (vm.hasProfile)
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
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
    );
  }

  // Thẻ tính năng AI phân tích ghi chú tự do (chỉ hiển thị giao diện)
  Widget _buildAiBannerCard() {
    return Container(
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
          if (subtitle != null) ...[
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

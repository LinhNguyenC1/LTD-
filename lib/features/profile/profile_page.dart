import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'delete_confirm_dialog.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Personal Info & Account
  final TextEditingController nameController =
      TextEditingController(text: 'Linh');
  bool isLoggedIn = false;

  // Allergies
  bool milk = true;
  bool peanut = true;
  bool gluten = false;

  // Limits
  bool limitSugar = true;
  double sugarLimitVal = 10.0;
  bool limitSalt = true;
  double saltLimitVal = 0.30;
  bool avoidNova4 = true;

  // Diet
  String selectedDiet = 'Ăn chay có trứng và sữa';
  final List<String> diets = [
    'Ăn chay có trứng và sữa',
    'Ăn chay có sữa',
    'Ăn chay có trứng',
    'Thuần chay',
    'Chế độ Keto',
  ];

  // Goals
  bool goalWeightLoss = true;
  bool goalMaintainWeight = false;
  bool goalBuildMuscle = false;
  bool goalHealth = false;

  // AI Notes / Custom Context
  final TextEditingController aiNotesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hồ sơ ăn uống',
                style: TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 22, color: inkText)),
            Text('Tiêu chí của bạn, lựa chọn của bạn',
                style: TextStyle(fontSize: 12, color: subText)),
          ],
        ),
        backgroundColor: canvasBg,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Chọn những điều bạn muốn kiểm tra khi đọc nhãn thực phẩm.',
            style: TextStyle(fontSize: 14, color: subText),
          ),
          const SizedBox(height: 16),

          // Section 0: Thông tin cá nhân & Đồng bộ Tài khoản
          _buildCard(
            title: 'Tên xưng hô & Đồng bộ tài khoản',
            icon: Icons.account_circle_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tên hiển thị / Tên xưng hô:',
                    style: TextStyle(fontSize: 12, color: subText)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Nhập tên của bạn (ví dụ: Linh)',
                    filled: true,
                    fillColor: const Color(0xFFF4F6F3),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryGreen),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isLoggedIn
                        ? const Color(0xFFE8F2E7)
                        : const Color(0xFFF4F6F3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isLoggedIn ? Icons.cloud_done : Icons.cloud_outlined,
                        color: isLoggedIn ? primaryGreen : subText,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLoggedIn
                                  ? 'Đã đồng bộ Google (linh@gmail.com)'
                                  : 'Tài khoản Khách (Lưu trên máy)',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: inkText),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isLoggedIn
                                  ? 'Hồ sơ tự động sao lưu an toàn'
                                  : 'Đăng nhập 1-chạm bằng Google để sao lưu',
                              style:
                                  const TextStyle(fontSize: 11, color: subText),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => isLoggedIn = !isLoggedIn);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isLoggedIn
                                  ? 'Đã đồng bộ bằng Google thành công!'
                                  : 'Đã chuyển sang chế độ Khách'),
                              backgroundColor: primaryGreen,
                            ),
                          );
                        },
                        child: Text(
                          isLoggedIn ? 'Thoát' : 'Đồng bộ',
                          style: const TextStyle(
                              color: primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Section 1: Dị ứng thực phẩm
          _buildCard(
            title: 'Dị ứng thực phẩm',
            icon: Icons.shield_outlined,
            child: Column(
              children: [
                _buildCheckRow(
                  title: 'Sữa',
                  subtitle: 'Kiểm tra sữa và thành phần từ sữa',
                  value: milk,
                  onChanged: (v) => setState(() => milk = v ?? false),
                ),
                _buildCheckRow(
                  title: 'Đậu phộng',
                  subtitle: 'Kiểm tra đậu phộng trong nhãn',
                  value: peanut,
                  onChanged: (v) => setState(() => peanut = v ?? false),
                ),
                _buildCheckRow(
                  title: 'Gluten',
                  subtitle: gluten ? 'Đã chọn trong hồ sơ' : 'Chưa chọn trong hồ sơ này',
                  value: gluten,
                  onChanged: (v) => setState(() => gluten = v ?? false),
                ),
              ],
            ),
          ),

          // Section 2: Mức hạn chế cá nhân
          _buildCard(
            title: 'Mức hạn chế cá nhân',
            icon: Icons.tune,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCheckRow(
                  title: 'Hạn chế đường',
                  subtitle: 'Theo tổng lượng đường ghi trên nhãn',
                  value: limitSugar,
                  onChanged: (v) => setState(() => limitSugar = v ?? false),
                ),
                if (limitSugar)
                  Padding(
                    padding: const EdgeInsets.only(left: 36, bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F4EF),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('≤ 10 g',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('trên 100 g',
                              style: TextStyle(color: subText, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                _buildCheckRow(
                  title: 'Hạn chế muối',
                  subtitle: 'Theo lượng muối ghi trên nhãn',
                  value: limitSalt,
                  onChanged: (v) => setState(() => limitSalt = v ?? false),
                ),
                if (limitSalt)
                  Padding(
                    padding: const EdgeInsets.only(left: 36, bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F4EF),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('≤ 0,30 g',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('trên 100 g',
                              style: TextStyle(color: subText, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    'Các mức tự chọn ở đây dùng cho bài tập minh họa, không phải ngưỡng y khoa.',
                    style: TextStyle(fontSize: 11, color: subText),
                  ),
                ),
                const SizedBox(height: 8),
                _buildCheckRow(
                  title: 'Tránh thực phẩm NOVA 4',
                  subtitle: 'Nhóm thực phẩm siêu chế biến theo NOVA',
                  value: avoidNova4,
                  onChanged: (v) => setState(() => avoidNova4 = v ?? false),
                ),
              ],
            ),
          ),

          // Section 3: Chế độ ăn
          _buildCard(
            title: 'Chế độ ăn',
            icon: Icons.restaurant_menu_outlined,
            child: Column(
              children: diets
                  .map((diet) => InkWell(
                        onTap: () => setState(() => selectedDiet = diet),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                selectedDiet == diet
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: selectedDiet == diet
                                    ? primaryGreen
                                    : subText,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                diet,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14),
                              )
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Section 4: Mục tiêu dinh dưỡng
          _buildCard(
            title: 'Mục tiêu dinh dưỡng',
            icon: Icons.auto_graph,
            child: Column(
              children: [
                _buildCheckRow(
                  title: 'Giảm cân',
                  subtitle: '',
                  value: goalWeightLoss,
                  onChanged: (v) => setState(() => goalWeightLoss = v ?? false),
                ),
                _buildCheckRow(
                  title: 'Duy trì cân nặng',
                  subtitle: '',
                  value: goalMaintainWeight,
                  onChanged: (v) =>
                      setState(() => goalMaintainWeight = v ?? false),
                ),
                _buildCheckRow(
                  title: 'Tăng cơ',
                  subtitle: '',
                  value: goalBuildMuscle,
                  onChanged: (v) =>
                      setState(() => goalBuildMuscle = v ?? false),
                ),
                _buildCheckRow(
                  title: 'Cải thiện sức khỏe tổng thể',
                  subtitle: '',
                  value: goalHealth,
                  onChanged: (v) => setState(() => goalHealth = v ?? false),
                ),
              ],
            ),
          ),

          // Section 5: Ghi chú thêm (AI Prompt Context)
          _buildCard(
            title: 'Ghi chú thêm (AI)',
            icon: Icons.psychology_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bạn có thể mô tả chi tiết chế độ dinh dưỡng, sở thích, mục tiêu dinh dưỡng, các thành phần bạn dị ứng hoặc cần AI tư vấn thêm...',
                  style: TextStyle(fontSize: 12, color: subText),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: aiNotesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'Ví dụ: Tôi dị ứng hải sản nặng, thích sản phẩm có nhiều chất xơ, không thích đường hóa học...',
                    hintStyle:
                        const TextStyle(fontSize: 12, color: Colors.black38),
                    filled: true,
                    fillColor: const Color(0xFFF4F6F3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryGreen),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Notice Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F2E7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 20, color: primaryGreen),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Hồ sơ chỉ lưu trên thiết bị này. Không cần tài khoản. Bạn có thể chỉnh sửa hoặc xóa hồ sơ bất cứ lúc nào.',
                    style: TextStyle(fontSize: 12, color: inkText, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã lưu hồ sơ ăn uống cá nhân!'),
                  backgroundColor: primaryGreen,
                ),
              );
            },
            icon: const Icon(Icons.check),
            label: const Text('Lưu hồ sơ',
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: FilledButton.styleFrom(
              backgroundColor: primaryGreen,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 10),

          OutlinedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => const DeleteConfirmDialog(),
              );
              if (confirm == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa và đặt lại hồ sơ mặc định'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete_outline, color: Color(0xFFB23A2B)),
            label: const Text(
              'Xóa hồ sơ',
              style: TextStyle(
                  color: Color(0xFFB23A2B), fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: cardBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 14),

          const Text(
            'Khi thay đổi tiêu chí, hãy mở lại sản phẩm để xem đánh giá mới. Xóa hồ sơ cần xác nhận và không xóa lịch sử.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: subText),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: primaryGreen),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildCheckRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: primaryGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                if (subtitle.isNotEmpty)
                  Text(subtitle,
                      style: const TextStyle(fontSize: 11, color: subText)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/models/food.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/status_badge.dart';

class ExplanationPage extends StatelessWidget {
  const ExplanationPage({super.key, required this.food});
  final Food food;

  @override
  Widget build(BuildContext context) {
    final bool isBad = food.result == Result.bad;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vì sao có kết quả này?',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18, color: inkText)),
            Text('${food.name} · ${food.brand}',
                style: const TextStyle(fontSize: 12, color: subText)),
          ],
        ),
        backgroundColor: canvasBg,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          StatusBadge(result: food.result, fontSize: 14),
          const SizedBox(height: 14),

          Text(
            isBad
                ? 'Kết luận dựa trên 5 tiêu chí bạn đã chọn. Dị ứng sữa và NOVA 4 là các lý do quyết định.'
                : food.reason,
            style: const TextStyle(fontSize: 14, color: inkText, height: 1.4),
          ),
          const SizedBox(height: 16),

          // Criterion 1: Dị ứng sữa
          _buildCriterionCard(
            title: 'Dị ứng sữa',
            icon: Icons.cancel_outlined,
            iconColor: const Color(0xFFB23A2B),
            description: food.ingredients.contains('sữa')
                ? 'Thành phần ghi rõ “bột sữa 8%”. Đây là thành phần từ sữa, trùng tiêu chí dị ứng của bạn.'
                : 'Thông tin dị ứng đầy đủ; không ghi nhận thành phần từ sữa.',
            badgeText: food.ingredients.contains('sữa')
                ? 'Có bằng chứng vi phạm ➔ Không phù hợp'
                : 'Không vi phạm tiêu chí này',
            badgeBg: food.ingredients.contains('sữa')
                ? const Color(0xFFFCEAE6)
                : const Color(0xFFE4F1E5),
            badgeTextColor: food.ingredients.contains('sữa')
                ? const Color(0xFFB23A2B)
                : primaryGreen,
          ),

          // Criterion 2: Dị ứng đậu phộng
          _buildCriterionCard(
            title: 'Dị ứng đậu phộng',
            icon: Icons.check_circle_outline,
            iconColor: primaryGreen,
            description:
                'Thông tin dị ứng minh họa đầy đủ: có sữa, gluten, đậu nành; không ghi nhận đậu phộng.',
            badgeText: 'Không vi phạm tiêu chí này trong dữ liệu hiện có',
            badgeBg: const Color(0xFFE4F1E5),
            badgeTextColor: primaryGreen,
          ),

          // Criterion 3: Hạn chế đường
          _buildCriterionCard(
            title: 'Hạn chế đường',
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFF8C600F),
            description:
                'Đường ${food.sugar}/100 g. Mức cá nhân đã lưu: tối đa 10 g/100 g, chênh +8 g.',
            badgeText: 'Vượt mức cá nhân ➔ Cần cân nhắc',
            badgeBg: const Color(0xFFFDF5E2),
            badgeTextColor: const Color(0xFF8C600F),
          ),

          // Criterion 4: Hạn chế muối
          _buildCriterionCard(
            title: 'Hạn chế muối',
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFF8C600F),
            description:
                'Muối ${food.salt}/100 g. Mức cá nhân đã lưu: tối đa 0,30 g/100 g, chênh +0,12 g.',
            badgeText: 'Vượt mức cá nhân ➔ Cần cân nhắc',
            badgeBg: const Color(0xFFFDF5E2),
            badgeTextColor: const Color(0xFF8C600F),
          ),

          // Criterion 5: Tránh NOVA 4
          _buildCriterionCard(
            title: 'Tránh NOVA 4',
            icon: food.nova == '4'
                ? Icons.cancel_outlined
                : Icons.check_circle_outline,
            iconColor: food.nova == '4'
                ? const Color(0xFFB23A2B)
                : primaryGreen,
            description: food.nova == '4'
                ? 'Dữ liệu minh họa xếp sản phẩm ở NOVA 4, nhóm thực phẩm siêu chế biến mà bạn chọn tránh.'
                : 'Sản phẩm thuộc NOVA ${food.nova}.',
            badgeText: food.nova == '4'
                ? 'Trùng tiêu chí cần tránh ➔ Không phù hợp'
                : 'Phù hợp tiêu chí NOVA',
            badgeBg: food.nova == '4'
                ? const Color(0xFFFCEAE6)
                : const Color(0xFFE4F1E5),
            badgeTextColor: food.nova == '4'
                ? const Color(0xFFB23A2B)
                : primaryGreen,
          ),

          const SizedBox(height: 10),

          // Required Data Notice Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xFF385570), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Dữ liệu cần thiết đã có\nKhông thiếu thành phần, thông tin dị ứng, đường, muối hoặc NOVA cho lần đánh giá này. Gluten không được chọn nên không tham gia kết luận.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF2C4359), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Các mức đường và muối là lựa chọn cá nhân trong bài tập, không phải ngưỡng y khoa. Nutri-Score C và Eco-Score B không thay thế việc kiểm tra dị ứng.\n\nChỉ mang tính tham khảo theo hồ sơ cá nhân, không phải chẩn đoán hay lời khuyên sức khỏe chung. Luôn kiểm tra nhãn thực tế.',
            style: TextStyle(fontSize: 11, color: subText, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildCriterionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String description,
    required String badgeText,
    required Color badgeBg,
    required Color badgeTextColor,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description,
                style: const TextStyle(fontSize: 13, color: inkText, height: 1.35)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: badgeTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

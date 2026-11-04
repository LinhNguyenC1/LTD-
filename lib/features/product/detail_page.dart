import 'package:flutter/material.dart';
import '../../core/models/food.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../widgets/pack_widget.dart';
import 'explanation_page.dart';
import '../compare/compare_select_page.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.food});
  final Food food;

  @override
  Widget build(BuildContext context) {
    final bool isUnknown = food.result == Result.unknown;
    final bool isBad = food.result == Result.bad;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chi tiết sản phẩm',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18, color: inkText)),
            Text('Đánh giá theo hồ sơ đang lưu',
                style: TextStyle(fontSize: 12, color: subText)),
          ],
        ),
        backgroundColor: canvasBg,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Product Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: getResultBg(food.result),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                PackWidget(food: food, small: false),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${food.brand} · ${food.weight}',
                          style:
                              const TextStyle(color: subText, fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(
                        food.name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900, height: 1.2),
                      ),
                      const SizedBox(height: 10),
                      Text('Mã vạch ${food.barcode}',
                          style:
                              const TextStyle(color: subText, fontSize: 11)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Main Evaluation Result Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: getResultBg(food.result),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusBadge(result: food.result, fontSize: 13),
                const SizedBox(height: 12),
                Text(
                  isBad
                      ? 'Có sữa, không hợp hồ sơ của bạn'
                      : isUnknown
                          ? 'Chưa thể kết luận phù hợp'
                          : 'Phù hợp với hồ sơ của bạn',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  food.reason,
                  style: const TextStyle(fontSize: 13, color: inkText, height: 1.4),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExplanationPage(food: food),
                      ),
                    );
                  },
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('Xem giải thích theo tiêu chí'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: cardBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 1: Thành phần
          _buildInfoCard(
            title: 'Thành phần',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food.ingredients,
                    style: const TextStyle(fontSize: 13, height: 1.4)),
                const SizedBox(height: 12),
                if (food.allergenWarning != 'Chưa có dữ liệu')
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isBad
                          ? const Color(0xFFFCEAE6)
                          : const Color(0xFFE4F1E5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isBad
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline,
                          color: isBad
                              ? const Color(0xFFB23A2B)
                              : primaryGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isBad
                                    ? 'Dị ứng được ghi nhận'
                                    : 'Kiểm tra dị ứng',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isBad
                                      ? const Color(0xFFB23A2B)
                                      : primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                food.allergenWarning,
                                style: const TextStyle(
                                    fontSize: 11, color: inkText),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  )
              ],
            ),
          ),

          // Section 2: Dinh dưỡng
          _buildInfoCard(
            title: 'Dinh dưỡng',
            trailing: 'Trên 100 g',
            child: Column(
              children: [
                _buildDataRow('Đường', food.sugar),
                _buildDataRow('Muối', food.salt),
                const SizedBox(height: 8),
                const Text(
                  'Vượt mức cá nhân: đường 10 g và muối 0,30 g trên 100 g. Đây không phải ngưỡng y khoa.',
                  style: TextStyle(fontSize: 11, color: subText),
                ),
              ],
            ),
          ),

          // Section 3: Thông tin bổ sung
          _buildInfoCard(
            title: 'Thông tin bổ sung',
            child: Column(
              children: [
                _buildDataRow('NOVA', food.nova),
                _buildDataRow('Nutri-Score', food.nutriScore),
                _buildDataRow('Eco-Score', food.ecoScore),
                const SizedBox(height: 8),
                const Text(
                  'Nutri-Score và Eco-Score không cho biết sản phẩm có an toàn với dị ứng của bạn hay không.',
                  style: TextStyle(fontSize: 11, color: subText),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // GỢI Ý SẢN PHẨM PHÙ HỢP HƠN (AI & Rule Based Recommended Alternatives)
          if (food.id != foodOriginal.id)
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: primaryGreen, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: primaryGreen, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Gợi ý sản phẩm phù hợp hơn',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Dựa trên hồ sơ ăn uống cá nhân của bạn, đây là lựa chọn thay thế tốt hơn:',
                      style: TextStyle(fontSize: 12, color: subText),
                    ),
                    const SizedBox(height: 12),

                    // Alternative Product Card
                    InkWell(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DetailPage(food: foodOriginal),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F2E7),
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                        child: Row(
                          children: [
                            const PackWidget(food: foodOriginal, small: true),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(foodOriginal.brand,
                                      style: const TextStyle(
                                          fontSize: 11, color: subText)),
                                  Text(
                                    foodOriginal.name,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  StatusBadge(result: foodOriginal.result),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '✓ Không chứa sữa · NOVA 3 · Ít đường',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward,
                                color: primaryGreen),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),

          // Referenced Products Section
          const Text(
            'Sản phẩm tham khảo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...mockFoods.where((item) => item.id != food.id).take(3).map((item) {
            return Card(
              elevation: 0,
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: cardBorder),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailPage(food: item),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      PackWidget(food: item, small: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.brand,
                                style: const TextStyle(
                                    fontSize: 11, color: subText)),
                            Text(item.name,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(result: item.result, fontSize: 10),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 14),

          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CompareSelectPage(initialFoodA: food),
                ),
              );
            },
            icon: const Icon(Icons.compare_arrows),
            label: const Text('Chọn 2 sản phẩm để so sánh'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: cardBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Dữ liệu minh họa · Đã xem hôm nay\nNguồn tra cứu dự kiến: Open Food Facts\nChỉ mang tính tham khảo theo hồ sơ cá nhân, không phải chẩn đoán hay lời khuyên sức khỏe chung.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: subText, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    String? trailing,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                if (trailing != null)
                  Text(trailing,
                      style: const TextStyle(fontSize: 11, color: subText)),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: subText)),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

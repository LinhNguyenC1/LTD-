import 'package:flutter/material.dart';
import '../../core/models/food.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/pack_widget.dart';
import 'compare_select_page.dart';

class CompareTablePage extends StatelessWidget {
  const CompareTablePage({super.key, required this.foodA, required this.foodB});
  final Food foodA;
  final Food foodB;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Đặt hai nhãn cạnh nhau',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18, color: inkText)),
            Text('Cùng nhóm bánh yến mạch',
                style: TextStyle(fontSize: 12, color: subText)),
          ],
        ),
        backgroundColor: canvasBg,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Side-by-side Product Headers
          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: cardBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        PackWidget(food: foodA, small: false),
                        const SizedBox(height: 8),
                        Text(foodA.brand,
                            style:
                                const TextStyle(fontSize: 11, color: subText)),
                        Text(
                          foodA.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(foodA.weight,
                            style:
                                const TextStyle(fontSize: 11, color: subText)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: cardBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        PackWidget(food: foodB, small: false),
                        const SizedBox(height: 8),
                        Text(foodB.brand,
                            style:
                                const TextStyle(fontSize: 11, color: subText)),
                        Text(
                          foodB.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(foodB.weight,
                            style:
                                const TextStyle(fontSize: 11, color: subText)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Decision Highlight Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F2E7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: primaryGreen, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Khác biệt quyết định: sữa và NOVA',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: inkText),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Với hồ sơ của bạn, bánh ${foodB.brand} phù hợp hơn với các tiêu chí đã lưu. Bánh ${foodA.brand} có sữa và thuộc NOVA 4.',
                        style:
                            const TextStyle(fontSize: 12, color: inkText, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Comparison Table Header
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: cardBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Table Header Row
                  Row(
                    children: [
                      const Expanded(
                        flex: 3,
                        child: Text('Theo hồ sơ',
                            style: TextStyle(
                                fontSize: 12,
                                color: subText,
                                fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(foodA.brand,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(foodB.brand,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Row: Kết luận cá nhân
                  _buildTableRow(
                    'Kết luận cá nhân',
                    foodA.result == Result.bad ? 'Không phù hợp' : getResultText(foodA.result),
                    getResultText(foodB.result),
                    highlightA: foodA.result == Result.bad,
                    highlightB: foodB.result == Result.good,
                  ),
                  const Divider(height: 16),

                  // Row: Dị ứng sữa
                  _buildTableRow(
                    'Dị ứng sữa',
                    foodA.ingredients.contains('sữa') ? 'Có sữa 8%' : 'Không chứa¹',
                    'Không chứa¹',
                    highlightA: foodA.ingredients.contains('sữa'),
                    highlightB: false,
                  ),
                  const Divider(height: 16),

                  // Row: Đậu phộng
                  _buildTableRow(
                    'Đậu phộng',
                    'Không ghi nhận',
                    'Không chứa¹',
                  ),
                  const Divider(height: 16),

                  // Row: Đường /100g
                  _buildTableRow(
                    'Đường /100 g',
                    foodA.sugar,
                    foodB.sugar,
                    highlightA: foodA.sugar.contains('18'),
                  ),
                  const Divider(height: 16),

                  // Row: Muối /100g
                  _buildTableRow(
                    'Muối /100 g',
                    foodA.salt,
                    foodB.salt,
                    highlightA: foodA.salt.contains('0,42'),
                  ),
                  const Divider(height: 16),

                  // Row: NOVA
                  _buildTableRow(
                    'NOVA',
                    foodA.nova,
                    foodB.nova,
                    highlightA: foodA.nova == '4',
                  ),
                  const Divider(height: 16),

                  // Row: Nutri-Score
                  _buildTableRow(
                    'Nutri-Score',
                    foodA.nutriScore,
                    foodB.nutriScore,
                  ),
                  const Divider(height: 16),

                  // Row: Eco-Score
                  _buildTableRow(
                    'Eco-Score',
                    foodA.ecoScore,
                    foodB.ecoScore,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.compare, size: 14, color: subText),
              SizedBox(width: 4),
              Text('Nền nhấn: khác biệt liên quan đến hồ sơ của bạn.',
                  style: TextStyle(fontSize: 11, color: subText)),
            ],
          ),
          const SizedBox(height: 20),

          // Explanation Card
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
                  Text('Vì sao ${foodB.brand} được đánh giá phù hợp?',
                      style:
                          const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  Text(
                    '¹ ${foodB.allergenWarning}\n\nThành phần: ${foodB.ingredients}',
                    style: const TextStyle(fontSize: 12, color: inkText, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Allergy Warning Notice
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xFF385570), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Không dùng điểm số để kết luận an toàn dị ứng.\nNutri-Score và Eco-Score là thông tin độc lập. Nếu thiếu một trường, bảng ghi “Chưa có dữ liệu”, không thay bằng 0.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF2C4359), height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          OutlinedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => CompareSelectPage(
                    initialFoodA: foodA,
                    initialFoodB: foodB,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.compare_arrows),
            label: const Text('Đổi cặp sản phẩm'),
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
            'Dữ liệu minh họa · Nguồn dự kiến: Open Food Facts\nĐường và muối cùng tính trên 100 g.\nChỉ mang tính tham khảo theo hồ sơ cá nhân, không phải chẩn đoán hay lời khuyên sức khỏe chung. Luôn kiểm tra nhãn thực tế.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: subText, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(
    String label,
    String valA,
    String valB, {
    bool highlightA = false,
    bool highlightB = false,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: subText)),
        ),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: highlightA
                  ? const Color(0xFFFCEAE6)
                  : (valA == 'Phù hợp' ? const Color(0xFFE4F1E5) : Colors.transparent),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              valA,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: highlightA ? const Color(0xFFB23A2B) : inkText,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: highlightB
                  ? const Color(0xFFE4F1E5)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              valB,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: highlightB ? primaryGreen : inkText,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/models/food.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../widgets/pack_widget.dart';
import 'compare_table_page.dart';

class CompareSelectPage extends StatefulWidget {
  const CompareSelectPage({super.key, this.initialFoodA, this.initialFoodB});
  final Food? initialFoodA;
  final Food? initialFoodB;

  @override
  State<CompareSelectPage> createState() => _CompareSelectPageState();
}

class _CompareSelectPageState extends State<CompareSelectPage> {
  late List<Food> selectedFoods;

  @override
  void initState() {
    super.initState();
    selectedFoods = [
      widget.initialFoodA ?? mockFoods[0],
      widget.initialFoodB ?? mockFoods[1],
    ];
  }

  void toggleSelection(Food food) {
    setState(() {
      if (selectedFoods.contains(food)) {
        if (selectedFoods.length > 1) {
          selectedFoods.remove(food);
        }
      } else {
        if (selectedFoods.length < 2) {
          selectedFoods.add(food);
        } else {
          selectedFoods.removeAt(0);
          selectedFoods.add(food);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool canCompare = selectedFoods.length == 2;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chọn sản phẩm',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18, color: inkText)),
            Text('So sánh từ các sản phẩm đã quét',
                style: TextStyle(fontSize: 12, color: subText)),
          ],
        ),
        backgroundColor: canvasBg,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Count Banner
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F2E7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: primaryGreen, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Đã chọn ${selectedFoods.length}/2 sản phẩm.\nMuốn đổi, hãy chọn hoặc bỏ chọn sản phẩm.',
                          style: const TextStyle(
                              fontSize: 12, color: inkText, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sản phẩm đã quét',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('${mockFoods.length} sản phẩm',
                        style: const TextStyle(fontSize: 12, color: subText)),
                  ],
                ),
                const SizedBox(height: 12),

                ...mockFoods.map((food) {
                  final isSelected = selectedFoods.contains(food);

                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: isSelected ? primaryGreen : cardBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => toggleSelection(food),
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            PackWidget(food: food, small: true),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(food.brand,
                                      style: const TextStyle(
                                          fontSize: 11, color: subText)),
                                  Text(food.name,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  StatusBadge(result: food.result),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${food.scanDate} · ${food.summaryTags}',
                                    style: const TextStyle(
                                        fontSize: 11, color: subText),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: isSelected ? primaryGreen : subText,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 10),
                const Text(
                  'Chọn đúng hai sản phẩm để bật nút so sánh. Sản phẩm thiếu dữ liệu vẫn có thể đối chiếu nhưng không được suy ra phù hợp.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: subText, height: 1.4),
                ),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(20),
            color: canvasBg,
            child: FilledButton.icon(
              onPressed: canCompare
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CompareTablePage(
                            foodA: selectedFoods[0],
                            foodB: selectedFoods[1],
                          ),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.compare_arrows),
              label: const Text('So sánh 2 sản phẩm',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                backgroundColor: primaryGreen,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

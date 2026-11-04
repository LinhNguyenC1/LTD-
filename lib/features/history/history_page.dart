import 'package:flutter/material.dart';
import '../../core/models/food.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../widgets/pack_widget.dart';
import '../compare/compare_select_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.onOpenFood});
  final void Function(Food) onOpenFood;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String selectedFilter = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    List<Food> filteredFoods = mockFoods;
    if (selectedFilter == 'Không phù hợp') {
      filteredFoods = mockFoods.where((f) => f.result == Result.bad).toList();
    } else if (selectedFilter == 'Chưa đủ dữ liệu') {
      filteredFoods =
          mockFoods.where((f) => f.result == Result.unknown).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('Lịch sử đánh giá',
                    style: TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 22, color: inkText)),
                Spacer(),
                Icon(Icons.eco_outlined, color: primaryGreen),
              ],
            ),
            Text('${mockFoods.length} sản phẩm · Lưu trên thiết bị',
                style: const TextStyle(fontSize: 12, color: subText)),
          ],
        ),
        backgroundColor: canvasBg,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Filter Chips
          Wrap(
            spacing: 8,
            children: ['Tất cả', 'Không phù hợp', 'Chưa đủ dữ liệu']
                .map((filter) {
              final isSelected = selectedFilter == filter;
              return ChoiceChip(
                label: Text(filter,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : inkText,
                    )),
                selected: isSelected,
                selectedColor: primaryGreen,
                backgroundColor: const Color(0xFFEAEFEA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onSelected: (val) {
                  if (val) setState(() => selectedFilter = filter);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Chọn một sản phẩm để xem lại kết luận và lý do theo hồ sơ.',
            style: TextStyle(fontSize: 13, color: subText),
          ),
          const SizedBox(height: 20),

          // Group 1: Hôm nay
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hôm nay',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('04 tháng 11',
                  style: TextStyle(fontSize: 12, color: subText)),
            ],
          ),
          const SizedBox(height: 10),
          ...filteredFoods.take(2).map((food) => _buildFoodCard(food)),

          const SizedBox(height: 16),

          // Group 2: Hôm qua
          if (filteredFoods.length > 2) ...[
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Hôm qua',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('03 tháng 11',
                    style: TextStyle(fontSize: 12, color: subText)),
              ],
            ),
            const SizedBox(height: 10),
            ...filteredFoods.skip(2).map((food) => _buildFoodCard(food)),
          ],

          const SizedBox(height: 20),

          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CompareSelectPage(),
                ),
              );
            },
            icon: const Icon(Icons.compare_arrows),
            label: const Text('Chọn 2 sản phẩm để so sánh',
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: cardBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 14),

          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.phone_android, size: 16, color: subText),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Các kết luận gắn với hồ sơ khi đánh giá. Khi đổi tiêu chí, mở lại sản phẩm để xem đánh giá theo hồ sơ hiện tại.',
                  style: TextStyle(fontSize: 11, color: subText, height: 1.35),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFoodCard(Food food) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: cardBorder),
      ),
      child: InkWell(
        onTap: () => widget.onOpenFood(food),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              PackWidget(food: food, small: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(food.brand,
                        style: const TextStyle(fontSize: 11, color: subText)),
                    Text(food.name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    StatusBadge(result: food.result),
                    const SizedBox(height: 6),
                    Text(
                      '${food.scanDate} · ${food.summaryTags}',
                      style: const TextStyle(fontSize: 11, color: subText),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: subText),
            ],
          ),
        ),
      ),
    );
  }
}

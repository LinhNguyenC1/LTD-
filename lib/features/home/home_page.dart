import 'package:flutter/material.dart';
import '../../core/models/food.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../widgets/pack_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.onScan,
    required this.onOpenFood,
    required this.onEditProfile,
    required this.onCompare,
  });

  final VoidCallback onScan;
  final void Function(Food) onOpenFood;
  final VoidCallback onEditProfile;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    final recentFood = mockFoods.first;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Top Brand Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ăn Lành',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: inkText,
                  ),
                ),
                Text(
                  'Hiểu nhãn. Chọn theo mình.',
                  style: TextStyle(fontSize: 13, color: subText),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.eco_outlined, color: primaryGreen),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.wb_sunny_outlined, color: subText),
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Chào Thuý Linh, cùng đọc nhãn nhé! 👋',
          style: TextStyle(fontSize: 15, color: subText),
        ),
        const SizedBox(height: 14),

        // Banner 1: Single Scan
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1E7),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Một lần quét.\nHiểu rõ hơn.',
                          style: TextStyle(
                            fontSize: 26,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                            color: inkText,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Xem thực phẩm có phù hợp với hồ sơ ăn uống của bạn.',
                          style: TextStyle(fontSize: 13, color: inkText),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Product Preview Badge Illustration
                  Container(
                    width: 78,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2EDDF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC8DCBE)),
                    ),
                    child: const Column(
                      children: [
                        PackWidget(food: foodOriginal, small: true),
                        SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.fact_check_outlined,
                                  size: 10, color: primaryGreen),
                              SizedBox(width: 2),
                              Text('Có căn cứ',
                                  style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: primaryGreen)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onScan,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Quét mã vạch',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: primaryGreen,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Active Profile Card
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline, color: primaryGreen),
                    const SizedBox(width: 8),
                    const Text(
                      'Hồ sơ đang áp dụng',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onEditProfile,
                      child: const Text('Chỉnh sửa',
                          style: TextStyle(
                              color: primaryGreen,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Wrap(
                  spacing: 6,
                  children: [
                    Chip(
                      label: Text('Dị ứng sữa', style: TextStyle(fontSize: 11)),
                      backgroundColor: Color(0xFFF2F4F2),
                      visualDensity: VisualDensity.compact,
                    ),
                    Chip(
                      label:
                          Text('Dị ứng đậu phộng', style: TextStyle(fontSize: 11)),
                      backgroundColor: Color(0xFFF2F4F2),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hạn chế đường, muối · Tránh NOVA 4',
                  style: TextStyle(color: subText, fontSize: 13),
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.phone_android, size: 14, color: subText),
                    SizedBox(width: 4),
                    Text(
                      'Đã lưu trên thiết bị này',
                      style: TextStyle(fontSize: 11, color: subText),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Compare Card Button
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: cardBorder),
          ),
          child: InkWell(
            onTap: onCompare,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.compare_arrows, color: primaryGreen),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đặt hai nhãn cạnh nhau',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Chọn 2 sản phẩm đã quét để so sánh',
                          style: TextStyle(fontSize: 12, color: subText),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: subText),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Recent Evaluations Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Đánh giá gần đây',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Tất cả', style: TextStyle(color: primaryGreen)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Recent Food Tile Card
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: cardBorder),
          ),
          child: InkWell(
            onTap: () => onOpenFood(recentFood),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  PackWidget(food: recentFood, small: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recentFood.brand,
                            style:
                                const TextStyle(fontSize: 11, color: subText)),
                        Text(
                          recentFood.name,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        StatusBadge(result: recentFood.result),
                        const SizedBox(height: 6),
                        Text(
                          '${recentFood.scanDate} · ${recentFood.summaryTags}',
                          style:
                              const TextStyle(fontSize: 11, color: subText),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: subText),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Footer Disclaimer
        const Text(
          'Đánh giá theo hồ sơ cá nhân, chỉ mang tính tham khảo. Dữ liệu trong bản thiết kế là minh họa.',
          style: TextStyle(fontSize: 11, color: subText, height: 1.4),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

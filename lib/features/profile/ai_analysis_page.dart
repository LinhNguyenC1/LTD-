import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AiAnalysisPage extends StatefulWidget {
  const AiAnalysisPage({super.key, required this.noteText});
  final String noteText;

  @override
  State<AiAnalysisPage> createState() => _AiAnalysisPageState();
}

class _AiAnalysisPageState extends State<AiAnalysisPage> {
  // 5 Extracted Criteria States
  bool cMilk = true;
  bool cPeanut = true;
  bool cSugar = true;
  bool cSalt = true;
  bool cVeg = true;

  @override
  Widget build(BuildContext context) {
    final int selectedCount = [cMilk, cPeanut, cSugar, cSalt, cVeg]
        .where((item) => item)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn chọn, AI gợi ý',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18, color: inkText)),
            Text('Hồ sơ của Linh · Chờ xác nhận áp dụng',
                style: TextStyle(fontSize: 12, color: subText)),
          ],
        ),
        backgroundColor: canvasBg,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F1E5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 14, color: primaryGreen),
                    SizedBox(width: 4),
                    Text('Đã nhận gợi ý',
                        style: TextStyle(
                            color: primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Xem lại những điều AI hiểu từ ghi chú. Chỉ áp dụng các mục bạn đồng ý; hồ sơ chưa thay đổi.',
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
                  const Text('Ghi chú của bạn',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
                          : 'Tôi dị ứng sữa và đậu phộng, muốn giảm đường và muối, ưu tiên món chay',
                      style: const TextStyle(fontSize: 13, color: inkText, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Permission Banner Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F2E7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, color: primaryGreen, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Đã cho phép xử lý ghi chú lần này',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: primaryGreen)),
                      SizedBox(height: 4),
                      Text(
                        'Ghi chú đã được gửi cho dịch vụ AI sau khi bạn đồng ý. Quyền này chỉ dành cho lần gửi vừa rồi, không phải đồng ý cho mọi lần sau.\n\nMặc định không chia sẻ. Mỗi lần gửi mới đều cần bạn cho phép trước.',
                        style: TextStyle(fontSize: 11, color: inkText, height: 1.35),
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
              const Text('Tiêu chí bạn muốn giữ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('$selectedCount mục',
                  style: const TextStyle(fontSize: 12, color: subText)),
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
              child: Column(
                children: [
                  _buildCriteriaCheckRow(
                    title: 'Dị ứng sữa',
                    subtitle: 'Đã có trong hồ sơ · Giữ nguyên',
                    quote: '“Tôi dị ứng sữa”',
                    value: cMilk,
                    onChanged: (v) => setState(() => cMilk = v ?? false),
                  ),
                  const Divider(height: 20),
                  _buildCriteriaCheckRow(
                    title: 'Dị ứng đậu phộng',
                    subtitle: 'Đã có trong hồ sơ · Giữ nguyên',
                    quote: '“và đậu phộng”',
                    value: cPeanut,
                    onChanged: (v) => setState(() => cPeanut = v ?? false),
                  ),
                  const Divider(height: 20),
                  _buildCriteriaCheckRow(
                    title: 'Hạn chế đường',
                    subtitle: 'Giữ mức bạn đã chọn: ≤ 10 g/100 g',
                    quote: '“muốn giảm đường”',
                    value: cSugar,
                    onChanged: (v) => setState(() => cSugar = v ?? false),
                  ),
                  const Divider(height: 20),
                  _buildCriteriaCheckRow(
                    title: 'Hạn chế muối',
                    subtitle: 'Giữ mức bạn đã chọn: ≤ 0,30 g/100 g',
                    quote: '“và muối”',
                    value: cSalt,
                    onChanged: (v) => setState(() => cSalt = v ?? false),
                  ),
                  const Divider(height: 20),
                  _buildCriteriaCheckRow(
                    title: 'Ưu tiên món chay',
                    subtitle: 'Giữ chế độ hiện tại: chay có trứng và sữa',
                    quote: '“ưu tiên món chay”',
                    value: cVeg,
                    onChanged: (v) => setState(() => cVeg = v ?? false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Notice Card 1: Mức cá nhân do bạn chọn
          Container(
            padding: const EdgeInsets.all(14),
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
                      Text('Mức cá nhân do bạn chọn',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF2C4359))),
                      SizedBox(height: 2),
                      Text(
                        'Đường ≤ 10 g và muối ≤ 0,30 g trên 100 g đã có trong hồ sơ. AI không đặt mức mới; đây không phải ngưỡng y khoa.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF2C4359), height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Notice Card 2: Dị ứng luôn được ưu tiên
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8EA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Color(0xFF8C600F), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dị ứng luôn được ưu tiên',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF6E4B0B))),
                      SizedBox(height: 2),
                      Text(
                        'Chế độ chay có trứng và sữa không cho phép bỏ qua dị ứng sữa. Không tự thêm gluten hoặc thay mục tiêu giảm cân và tiêu chí tránh NOVA 4.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF6E4B0B), height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'Gợi ý “món chay” chưa đủ để tự đổi loại chế độ ăn. Bạn có thể chỉnh lựa chọn cụ thể trong Hồ sơ.',
            style: TextStyle(fontSize: 11, color: subText),
          ),
          const SizedBox(height: 20),

          // Bottom Action Button
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context, selectedCount);
            },
            icon: const Icon(Icons.check),
            label: Text('Xác nhận áp dụng $selectedCount mục đã chọn',
                style: const TextStyle(fontWeight: FontWeight.bold)),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14, color: inkText)),
              Text(subtitle,
                  style: const TextStyle(fontSize: 11, color: subText)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('Từ ghi chú: ',
                      style: TextStyle(fontSize: 11, color: subText)),
                  Expanded(
                    child: Text(
                      quote,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen),
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

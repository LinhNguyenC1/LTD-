import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class LookupNotFoundPage extends StatelessWidget {
  const LookupNotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tra cứu sản phẩm',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18, color: inkText)),
            Text('Đã đọc được mã vạch',
                style: TextStyle(fontSize: 12, color: subText)),
          ],
        ),
        backgroundColor: canvasBg,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 10),
          const Center(
            child: CircleAvatar(
              radius: 46,
              backgroundColor: Color(0xFFFAF3E5),
              child: Icon(Icons.inventory_2_outlined,
                  size: 40, color: Color(0xFF966C15)),
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code, size: 16, color: subText),
              SizedBox(width: 6),
              Text('8930000000999',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: subText)),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Chưa tìm thấy sản phẩm\nnày',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900, height: 1.2),
          ),
          const SizedBox(height: 12),
          const Text(
            'Mã đã được đọc nhưng không có bản ghi sản phẩm trong kết quả tra cứu. Điều này không nói lên sản phẩm có phù hợp với bạn hay không.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: inkText, height: 1.4),
          ),
          const SizedBox(height: 20),

          // Notice Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8EA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 20, color: Color(0xFF8C600F)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Chưa tạo đánh giá cá nhân. Không có dữ liệu để đối chiếu với hồ sơ. Sản phẩm chưa được thêm vào lịch sử đánh giá.',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF6E4B0B), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Guide Container
          const Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              side: BorderSide(color: cardBorder),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bạn có thể làm gì?',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 6),
                  Text(
                    'Kiểm tra mã trên bao bì và quét lại trong điều kiện đủ sáng. Nếu mã đúng, sản phẩm có thể chưa có trong nguồn dữ liệu dự kiến.',
                    style: TextStyle(fontSize: 13, color: subText),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Quét lại mã vạch'),
            style: FilledButton.styleFrom(
              backgroundColor: primaryGreen,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Về Trang chủ'),
          ),
          const SizedBox(height: 20),
          const Text(
            'Nguồn tra cứu dự kiến: Open Food Facts. Dữ liệu trong bản thiết kế là minh họa.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: subText),
          ),
        ],
      ),
    );
  }
}

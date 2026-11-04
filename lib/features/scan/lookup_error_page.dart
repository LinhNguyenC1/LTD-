import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class LookupErrorPage extends StatelessWidget {
  const LookupErrorPage({super.key});

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
            Text('Chưa hoàn tất tra cứu',
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
              backgroundColor: Color(0xFFE6EFF7),
              child: Icon(Icons.wifi_off_rounded,
                  size: 40, color: Color(0xFF4A6075)),
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
            'Chưa kết nối được với\nnguồn dữ liệu',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900, height: 1.2),
          ),
          const SizedBox(height: 12),
          const Text(
            'Có thể mạng đang gián đoạn hoặc nguồn dữ liệu tạm thời không phản hồi. Chưa thể biết sản phẩm có trong nguồn dữ liệu hay không.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: inkText, height: 1.4),
          ),
          const SizedBox(height: 20),

          // Notice Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 20, color: Color(0xFF385570)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Đây là lỗi kết nối, không phải “không tìm thấy”. Chưa có kết quả để đánh giá theo hồ sơ. Sản phẩm chưa được thêm vào lịch sử đánh giá.',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF2C4359), height: 1.4),
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
                  Text('Thử các bước sau',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 6),
                  Text(
                    'Kiểm tra Wi-Fi hoặc dữ liệu di động, rồi thử tra cứu lại. Không cần quét lại nếu mã trên đúng.',
                    style: TextStyle(fontSize: 13, color: subText),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.refresh),
            label: const Text('Thử tra cứu lại'),
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

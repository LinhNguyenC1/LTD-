import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class DeleteConfirmDialog extends StatelessWidget {
  const DeleteConfirmDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundColor: Color(0xFFFDEAE6),
              child: Icon(Icons.delete_outline,
                  color: Color(0xFFB23A2B), size: 26),
            ),
            const SizedBox(height: 16),
            const Text(
              'Xóa hồ sơ ăn uống?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: inkText,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Các tiêu chí dị ứng và hạn chế đã lưu trên thiết bị sẽ bị xóa. Lịch sử đánh giá vẫn được giữ lại.\n\nBạn cần thiết lập hồ sơ mới để tiếp tục nhận đánh giá cá nhân. Không thể hoàn tác thao tác này.',
              style: TextStyle(fontSize: 13, color: subText, height: 1.4),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(context, false),
              style: FilledButton.styleFrom(
                backgroundColor: primaryGreen,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Giữ hồ sơ',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, true),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                side: const BorderSide(color: cardBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Xóa hồ sơ',
                style: TextStyle(
                  color: Color(0xFFB23A2B),
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

import 'package:flutter/material.dart';
import '../../core/models/food.dart';
import '../../core/theme/app_theme.dart';
import 'lookup_error_page.dart';
import 'lookup_not_found_page.dart';

enum ScanMode { barcode, barcodeFailed, ingredientList }

class ScanPage extends StatefulWidget {
  const ScanPage({super.key, required this.onOpenFood});
  final void Function(Food) onOpenFood;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  ScanMode scanMode = ScanMode.barcode;

  @override
  Widget build(BuildContext context) {
    final isIngredientMode = scanMode == ScanMode.ingredientList;
    final isFailed = scanMode == ScanMode.barcodeFailed;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isIngredientMode ? 'Quét bảng thành phần' : 'Quét mã vạch',
          style: const TextStyle(fontWeight: FontWeight.bold, color: inkText),
        ),
        backgroundColor: canvasBg,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline, color: primaryGreen),
          )
        ],
      ),
      body: Column(
        children: [
          // Camera Simulation Area
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Simulated Camera Feed Background
                Container(
                  width: double.infinity,
                  color: const Color(0xFF424A3E),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.camera_alt,
                          size: 64, color: Colors.white54),
                    ),
                  ),
                ),
                Container(color: Colors.black.withAlpha(90)),

                // Top Mode Badge
                Positioned(
                  top: 30,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isFailed ? Colors.white : primaryGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isFailed
                              ? Icons.error_outline
                              : Icons.center_focus_weak,
                          size: 16,
                          color: isFailed ? Colors.red : Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isFailed
                              ? 'Không quét được mã'
                              : isIngredientMode
                                  ? 'Đưa bảng thành phần vào khung'
                                  : 'Đưa mã vạch vào khung',
                          style: TextStyle(
                            color: isFailed ? Colors.red : Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Frame Viewfinder Overlay
                Container(
                  width: isIngredientMode ? 300 : 280,
                  height: isIngredientMode ? 260 : 180,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isFailed ? Colors.red : Colors.white,
                      width: 2.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Red scanning line
                      Container(
                        height: 2,
                        width: double.infinity,
                        color: isFailed ? Colors.red : primaryGreen,
                      ),
                      if (isFailed)
                        Positioned(
                          child: FilledButton.icon(
                            onPressed: () {
                              setState(() =>
                                  scanMode = ScanMode.ingredientList);
                            },
                            icon: const Icon(Icons.document_scanner),
                            label: const Text('Quét bảng thành phần'),
                            style: FilledButton.styleFrom(
                              backgroundColor: primaryGreen,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Flashlight Toggle
                Positioned(
                  bottom: 30,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        if (scanMode == ScanMode.barcode) {
                          scanMode = ScanMode.barcodeFailed;
                        } else if (scanMode == ScanMode.barcodeFailed) {
                          scanMode = ScanMode.ingredientList;
                        } else {
                          scanMode = ScanMode.barcode;
                        }
                      });
                    },
                    icon: const Icon(Icons.flashlight_on, size: 18),
                    label: Text(
                      isIngredientMode
                          ? 'Đổi sang Quét mã'
                          : isFailed
                              ? 'Quét bảng thành phần'
                              : 'Bật đèn',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF233B2B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Instruction Area
          Container(
            padding: const EdgeInsets.all(20),
            color: canvasBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isIngredientMode
                      ? 'Giữ bảng rõ và đủ sáng'
                      : 'Giữ mã rõ và đủ sáng',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  isIngredientMode
                      ? 'Giữ điện thoại ổn định. Ăn Lành sẽ dùng OCR để đọc bảng thành phần.'
                      : 'Giữ điện thoại ổn định. Ăn Lành sẽ dùng mã để tra cứu thông tin sản phẩm.',
                  style: const TextStyle(fontSize: 13, color: subText),
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: primaryGreen),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Không lưu ảnh từ camera. Nguồn tra cứu dự kiến: Open Food Facts.',
                        style: TextStyle(fontSize: 11, color: subText),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Action Simulation Buttons
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => widget.onOpenFood(mockFoods.first),
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Xem sản phẩm mẫu',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LookupErrorPage(),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                      child: const Text('Lỗi kết nối',
                          style: TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 4),
                    OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LookupNotFoundPage(),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                      child: const Text('Không thấy',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

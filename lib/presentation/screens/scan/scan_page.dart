import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../business_logic/viewmodels/scan_viewmodel.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validators/barcode_validator.dart';
import '../../../data/models/cached_product_adapter.dart';
import '../../../data/models/food.dart';
import 'lookup_error_page.dart';
import 'lookup_not_found_page.dart';

enum ScanMode { barcode, barcodeFailed, ingredientList, manualInput }

class ScanPage extends StatefulWidget {
  const ScanPage({super.key, required this.onOpenFood});
  final void Function(Food) onOpenFood;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage>
    with SingleTickerProviderStateMixin {
  ScanMode scanMode = ScanMode.barcode;
  bool flashOn = false;
  final TextEditingController barcodeController =
      TextEditingController(text: '8934567890123');
  String? _barcodeError;

  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -70.0, end: 70.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    barcodeController.dispose();
    super.dispose();
  }

  Future<void> _submitBarcode(String rawBarcode) async {
    final clean = rawBarcode.trim();
    if (!BarcodeValidator.isValid(clean)) {
      setState(() {
        _barcodeError = 'Mã vạch không hợp lệ (cần 8, 12 hoặc 13 chữ số)';
      });
      return;
    }

    setState(() {
      _barcodeError = null;
    });

    ScanViewModel? vm;
    try {
      vm = context.read<ScanViewModel>();
    } catch (_) {
      vm = null;
    }
    vm ??= ScanViewModel();

    try {
      final success = await vm.lookupBarcode(clean);
      if (!mounted) return;

      if (success && vm.scannedProduct != null) {
        widget.onOpenFood(vm.scannedProduct!.toFood());
      } else if (vm.isNotFound) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LookupNotFoundPage(barcode: clean),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LookupErrorPage(
              barcode: clean,
              errorMessage: vm?.errorMessage,
              onRetry: () => _submitBarcode(clean),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LookupErrorPage(
            barcode: clean,
            errorMessage: 'Lỗi tra cứu: $e',
            onRetry: () => _submitBarcode(clean),
          ),
        ),
      );
    }
  }

  void _showScanFailedPrompt() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFFFCEAE6),
                    child: Icon(Icons.qr_code_scanner,
                        color: Color(0xFFB23A2B), size: 22),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chưa nhận diện được mã vạch',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: inkText),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Mã có thể bị mờ, lóa sáng hoặc mất bao bì',
                          style: TextStyle(fontSize: 12, color: subText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Option 1: Quét bảng thành phần OCR
              Card(
                elevation: 0,
                color: const Color(0xFFE8F2E7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: primaryGreen),
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => scanMode = ScanMode.ingredientList);
                  },
                  leading: const Icon(Icons.document_scanner,
                      color: primaryGreen, size: 26),
                  title: const Text('Quét bảng thành phần (OCR)',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: primaryGreen)),
                  subtitle: const Text(
                      'Ăn Lành sẽ đọc danh sách thành phần trực tiếp từ mặt sau bao bì',
                      style: TextStyle(fontSize: 11, color: inkText)),
                  trailing:
                      const Icon(Icons.chevron_right, color: primaryGreen),
                ),
              ),
              const SizedBox(height: 10),

              // Option 2: Nhập mã thủ công
              Card(
                elevation: 0,
                color: const Color(0xFFF4F6F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: cardBorder),
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => scanMode = ScanMode.manualInput);
                  },
                  leading:
                      const Icon(Icons.keyboard, color: primaryGreen, size: 26),
                  title: const Text('Nhập mã vạch thủ công',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Gõ dãy số mã vạch in dưới đường kẻ',
                      style: TextStyle(fontSize: 11, color: subText)),
                  trailing: const Icon(Icons.chevron_right, color: subText),
                ),
              ),
              const SizedBox(height: 14),

              // Button: Thử quét lại
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => scanMode = ScanMode.barcode);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Thử quét lại mã vạch'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: cardBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIngredientMode = scanMode == ScanMode.ingredientList;
    final isFailed = scanMode == ScanMode.barcodeFailed;
    final isManual = scanMode == ScanMode.manualInput;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Camera Quét Sản Phẩm',
          style: TextStyle(fontWeight: FontWeight.bold, color: inkText),
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
          // Mode Switcher Segmented Bar
          Container(
            color: canvasBg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFEBEFEA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModeTab(
                      label: 'Mã vạch',
                      icon: Icons.qr_code_scanner,
                      isSelected: scanMode == ScanMode.barcode || isFailed,
                      onTap: () => setState(() => scanMode = ScanMode.barcode),
                    ),
                  ),
                  Expanded(
                    child: _buildModeTab(
                      label: 'Thành phần',
                      icon: Icons.document_scanner_outlined,
                      isSelected: isIngredientMode,
                      onTap: () =>
                          setState(() => scanMode = ScanMode.ingredientList),
                    ),
                  ),
                  Expanded(
                    child: _buildModeTab(
                      label: 'Nhập số',
                      icon: Icons.keyboard_outlined,
                      isSelected: isManual,
                      onTap: () =>
                          setState(() => scanMode = ScanMode.manualInput),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Camera View Area or Manual Input Area
          Expanded(
            child: isManual
                ? _buildManualInputView()
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      // Camera Background Simulation
                      Container(
                        width: double.infinity,
                        color: const Color(0xFF3B4438),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.camera_alt,
                                size: 64, color: Colors.white54),
                          ),
                        ),
                      ),
                      Container(
                          color: Colors.black.withAlpha(flashOn ? 30 : 100)),

                      // Mode Badge Banner
                      Positioned(
                        top: 24,
                        child: InkWell(
                          onTap: isFailed ? _showScanFailedPrompt : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isFailed ? Colors.white : primaryGreen,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isFailed
                                      ? Icons.warning_amber_rounded
                                      : isIngredientMode
                                          ? Icons.description_outlined
                                          : Icons.center_focus_weak,
                                  size: 16,
                                  color: isFailed ? Colors.red : Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isFailed
                                      ? 'Không quét được ➔ Bấm chọn cách khác'
                                      : isIngredientMode
                                          ? 'Đưa bảng thành phần vào khung OCR'
                                          : 'Đưa mã vạch vào khung',
                                  style: TextStyle(
                                    color: isFailed ? Colors.red : Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Viewfinder Frame Overlay
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
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
                            // Animated Scanner Laser Line
                            AnimatedBuilder(
                              animation: _animation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _animation.value),
                                  child: Container(
                                    height: 2,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color:
                                          isFailed ? Colors.red : primaryGreen,
                                      boxShadow: [
                                        BoxShadow(
                                          color: isFailed
                                              ? Colors.red
                                              : primaryGreen,
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Camera Bottom Controls
                      Positioned(
                        bottom: 24,
                        child: Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() => flashOn = !flashOn);
                              },
                              icon: Icon(
                                  flashOn
                                      ? Icons.flashlight_on
                                      : Icons.flashlight_off,
                                  size: 18),
                              label: Text(flashOn ? 'Tắt đèn' : 'Bật đèn'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF233B2B),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (isFailed) {
                                  _showScanFailedPrompt();
                                } else {
                                  setState(() {
                                    scanMode = ScanMode.barcodeFailed;
                                  });
                                  _showScanFailedPrompt();
                                }
                              },
                              icon: const Icon(Icons.help_outline, size: 18),
                              label: const Text('Lỗi quét?'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B2B24),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),

          // Bottom Controls & Simulation Panel
          if (!isManual)
            Container(
              padding: const EdgeInsets.all(20),
              color: canvasBg,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isManual
                      ? 'Nhập dãy số mã vạch'
                      : isIngredientMode
                          ? 'Giữ bảng thành phần rõ và đủ sáng'
                          : 'Giữ mã vạch rõ và đủ sáng',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  isManual
                      ? 'Hệ thống sẽ tra cứu thông tin sản phẩm trực tiếp từ số mã vạch.'
                      : isIngredientMode
                          ? 'Ăn Lành sẽ tự động trích xuất thành phần từ ảnh camera.'
                          : 'Ăn Lành sẽ đối chiếu mã với Open Food Facts để trả về kết quả.',
                  style: const TextStyle(fontSize: 12, color: subText),
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: primaryGreen),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Không lưu ảnh từ camera. Nguồn tra cứu: Open Food Facts.',
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
                      child: FilledButton.icon(
                        key: const Key('scan_preview_sample_button'),
                        onPressed: () =>
                            _submitBarcode(barcodeController.text.trim()),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Tra cứu mã vạch',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LookupErrorPage(
                            barcode: barcodeController.text.trim(),
                            onRetry: () =>
                                _submitBarcode(barcodeController.text.trim()),
                          ),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Lỗi kết nối',
                          style: TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 4),
                    OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LookupNotFoundPage(
                            barcode: barcodeController.text.trim(),
                          ),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

  Widget _buildModeTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  const BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? primaryGreen : subText,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryGreen : subText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualInputView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFE8F2E7),
                child: Icon(Icons.keyboard_outlined,
                    color: primaryGreen, size: 26),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tra cứu theo số mã vạch',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: inkText)),
                    Text('Nhập dãy số Barcode in trên nhãn sản phẩm',
                        style: TextStyle(fontSize: 12, color: subText)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            key: const Key('scan_barcode_input_field'),
            controller: barcodeController,
            keyboardType: TextInputType.number,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
            decoration: InputDecoration(
              labelText: 'Số mã vạch (EAN / UPC)',
              hintText: 'Ví dụ: 8934567890123',
              errorText: _barcodeError,
              prefixIcon: const Icon(Icons.qr_code, color: primaryGreen),
              filled: true,
              fillColor: const Color(0xFFF4F6F3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: primaryGreen, width: 2),
              ),
            ),
            onSubmitted: (val) => _submitBarcode(val),
            onChanged: (_) {
              if (_barcodeError != null) {
                setState(() => _barcodeError = null);
              }
            },
          ),
          const SizedBox(height: 16),

          // Submit Button
          FilledButton.icon(
            key: const Key('scan_manual_submit_button'),
            onPressed: () => _submitBarcode(barcodeController.text),
            icon: const Icon(Icons.search, size: 20),
            label: const Text(
              'Tra cứu ngay',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: primaryGreen,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Preset Simulation Chips
          const Text('Hoặc chọn nhanh mã sản phẩm mẫu:',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: inkText)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                key: const Key('chip_simulation_coca'),
                avatar: const Icon(Icons.local_drink, size: 16, color: primaryGreen),
                label: const Text('Coca-Cola (5449000000996)',
                    style: TextStyle(fontSize: 12)),
                onPressed: () {
                  setState(() {
                    barcodeController.text = '5449000000996';
                  });
                  _submitBarcode('5449000000996');
                },
              ),
              ActionChip(
                key: const Key('chip_simulation_nutella'),
                avatar: const Icon(Icons.cookie_outlined, size: 16, color: primaryGreen),
                label: const Text('Nutella (3017620422003)',
                    style: TextStyle(fontSize: 12)),
                onPressed: () {
                  setState(() {
                    barcodeController.text = '3017620422003';
                  });
                  _submitBarcode('3017620422003');
                },
              ),
              ActionChip(
                key: const Key('chip_simulation_cacao'),
                avatar: const Icon(Icons.bakery_dining_outlined, size: 16, color: primaryGreen),
                label: const Text('Bánh cacao (8934567890123)',
                    style: TextStyle(fontSize: 12)),
                onPressed: () {
                  setState(() {
                    barcodeController.text = '8934567890123';
                  });
                  _submitBarcode('8934567890123');
                },
              ),
              ActionChip(
                key: const Key('chip_simulation_original'),
                avatar: const Icon(Icons.grass, size: 16, color: primaryGreen),
                label: const Text('Bánh nguyên bản (8934567890456)',
                    style: TextStyle(fontSize: 12)),
                onPressed: () {
                  setState(() {
                    barcodeController.text = '8934567890456';
                  });
                  _submitBarcode('8934567890456');
                },
              ),
              ActionChip(
                key: const Key('chip_simulation_404'),
                avatar: const Icon(Icons.error_outline, size: 16, color: Colors.orange),
                label: const Text('404 test (0000000000000)',
                    style: TextStyle(fontSize: 12)),
                onPressed: () {
                  setState(() {
                    barcodeController.text = '0000000000000';
                  });
                  _submitBarcode('0000000000000');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

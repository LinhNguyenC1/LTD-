import 'package:flutter/material.dart';
import '../../core/models/food.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/status_badge.dart';

class ExplanationPage extends StatelessWidget {
  const ExplanationPage({super.key, required this.food});
  final Food food;

  void _openAiChatModal(BuildContext context, String initialQuestion) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AiChatModal(food: food, initialQuestion: initialQuestion),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isBad = food.result == Result.bad;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vì sao có kết quả này?',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18, color: inkText)),
            Text('${food.name} · ${food.brand}',
                style: const TextStyle(fontSize: 12, color: subText)),
          ],
        ),
        backgroundColor: canvasBg,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          StatusBadge(result: food.result, fontSize: 14),
          const SizedBox(height: 14),

          Text(
            isBad
                ? 'Kết luận dựa trên 5 tiêu chí bạn đã chọn. Dị ứng sữa và NOVA 4 là các lý do quyết định.'
                : food.reason,
            style: const TextStyle(fontSize: 14, color: inkText, height: 1.4),
          ),
          const SizedBox(height: 16),

          // Criterion 1: Dị ứng sữa
          _buildCriterionCard(
            title: 'Dị ứng sữa',
            icon: Icons.cancel_outlined,
            iconColor: const Color(0xFFB23A2B),
            description: food.ingredients.contains('sữa')
                ? 'Thành phần ghi rõ “bột sữa 8%”. Đây là thành phần từ sữa, trùng tiêu chí dị ứng của bạn.'
                : 'Thông tin dị ứng đầy đủ; không ghi nhận thành phần từ sữa.',
            badgeText: food.ingredients.contains('sữa')
                ? 'Có bằng chứng vi phạm ➔ Không phù hợp'
                : 'Không vi phạm tiêu chí này',
            badgeBg: food.ingredients.contains('sữa')
                ? const Color(0xFFFCEAE6)
                : const Color(0xFFE4F1E5),
            badgeTextColor: food.ingredients.contains('sữa')
                ? const Color(0xFFB23A2B)
                : primaryGreen,
          ),

          // Criterion 2: Dị ứng đậu phộng
          _buildCriterionCard(
            title: 'Dị ứng đậu phộng',
            icon: Icons.check_circle_outline,
            iconColor: primaryGreen,
            description:
                'Thông tin dị ứng minh họa đầy đủ: có sữa, gluten, đậu nành; không ghi nhận đậu phộng.',
            badgeText: 'Không vi phạm tiêu chí này trong dữ liệu hiện có',
            badgeBg: const Color(0xFFE4F1E5),
            badgeTextColor: primaryGreen,
          ),

          // Criterion 3: Hạn chế đường
          _buildCriterionCard(
            title: 'Hạn chế đường',
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFF8C600F),
            description:
                'Đường ${food.sugar}/100 g. Mức cá nhân đã lưu: tối đa 10 g/100 g, chênh +8 g.',
            badgeText: 'Vượt mức cá nhân ➔ Cần cân nhắc',
            badgeBg: const Color(0xFFFDF5E2),
            badgeTextColor: const Color(0xFF8C600F),
          ),

          // Criterion 4: Hạn chế muối
          _buildCriterionCard(
            title: 'Hạn chế muối',
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFF8C600F),
            description:
                'Muối ${food.salt}/100 g. Mức cá nhân đã lưu: tối đa 0,30 g/100 g, chênh +0,12 g.',
            badgeText: 'Vượt mức cá nhân ➔ Cần cân nhắc',
            badgeBg: const Color(0xFFFDF5E2),
            badgeTextColor: const Color(0xFF8C600F),
          ),

          // Criterion 5: Tránh NOVA 4
          _buildCriterionCard(
            title: 'Tránh NOVA 4',
            icon: food.nova == '4'
                ? Icons.cancel_outlined
                : Icons.check_circle_outline,
            iconColor: food.nova == '4'
                ? const Color(0xFFB23A2B)
                : primaryGreen,
            description: food.nova == '4'
                ? 'Dữ liệu minh họa xếp sản phẩm ở NOVA 4, nhóm thực phẩm siêu chế biến mà bạn chọn tránh.'
                : 'Sản phẩm thuộc NOVA ${food.nova}.',
            badgeText: food.nova == '4'
                ? 'Trùng tiêu chí cần tránh ➔ Không phù hợp'
                : 'Phù hợp tiêu chí NOVA',
            badgeBg: food.nova == '4'
                ? const Color(0xFFFCEAE6)
                : const Color(0xFFE4F1E5),
            badgeTextColor: food.nova == '4'
                ? const Color(0xFFB23A2B)
                : primaryGreen,
          ),

          const SizedBox(height: 10),

          // Interactive AI Assistant Box
          Card(
            elevation: 0,
            color: const Color(0xFFE8F2E7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: primaryGreen, width: 1.2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: primaryGreen, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Hỏi AI Chat thêm về sản phẩm',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Gõ câu hỏi tự do hoặc chọn câu hỏi gợi ý bên dưới:',
                    style: TextStyle(fontSize: 12, color: inkText),
                  ),
                  const SizedBox(height: 10),

                  // Quick Suggestion Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildAiPromptChip(context, 'Bánh này có hợp tập gym?'),
                      _buildAiPromptChip(context, 'Chất nhũ hóa Lecithin có an toàn?'),
                      _buildAiPromptChip(context, 'Trẻ em ăn được không?'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Interactive Custom Question Bar
                  InkWell(
                    onTap: () => _openAiChatModal(context, ''),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cardBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 16, color: subText),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Nhập câu hỏi bất kỳ cho Trợ lý AI...',
                              style: TextStyle(fontSize: 12, color: subText),
                            ),
                          ),
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: primaryGreen,
                            child: Icon(Icons.arrow_upward,
                                size: 14, color: Colors.white),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Required Data Notice Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF0F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xFF385570), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Dữ liệu cần thiết đã có\nKhông thiếu thành phần, thông tin dị ứng, đường, muối hoặc NOVA cho lần đánh giá này. Gluten không được chọn nên không tham gia kết luận.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF2C4359), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Các mức đường và muối là lựa chọn cá nhân trong bài tập, không phải ngưỡng y khoa. Nutri-Score C và Eco-Score B không thay thế việc kiểm tra dị ứng.\n\nChỉ mang tính tham khảo theo hồ sơ cá nhân, không phải chẩn đoán hay lời khuyên sức khỏe chung. Luôn kiểm tra nhãn thực tế.',
            style: TextStyle(fontSize: 11, color: subText, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildAiPromptChip(BuildContext context, String promptText) {
    return ActionChip(
      avatar: const Icon(Icons.chat_bubble_outline, size: 14, color: primaryGreen),
      label: Text(promptText, style: const TextStyle(fontSize: 11, color: inkText)),
      backgroundColor: Colors.white,
      side: const BorderSide(color: cardBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: () => _openAiChatModal(context, promptText),
    );
  }

  Widget _buildCriterionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String description,
    required String badgeText,
    required Color badgeBg,
    required Color badgeTextColor,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description,
                style: const TextStyle(fontSize: 13, color: inkText, height: 1.35)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: badgeTextColor,
                  fontSize: 12,
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

class _AiChatModal extends StatefulWidget {
  const _AiChatModal({required this.food, required this.initialQuestion});
  final Food food;
  final String initialQuestion;

  @override
  State<_AiChatModal> createState() => _AiChatModalState();
}

class _AiChatModalState extends State<_AiChatModal> {
  final TextEditingController _textController = TextEditingController();
  late List<Map<String, String>> _messages;

  @override
  void initState() {
    super.initState();
    final firstQ = widget.initialQuestion.isNotEmpty
        ? widget.initialQuestion
        : 'Sản phẩm này có an toàn với sức khỏe của tôi không?';
    _messages = [
      {'sender': 'user', 'text': firstQ},
      {'sender': 'ai', 'text': _generateAiResponse(firstQ, widget.food)}
    ];
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String _generateAiResponse(String question, Food food) {
    final lower = question.toLowerCase();
    if (lower.contains('gym') || lower.contains('tập')) {
      return 'Dựa trên hồ sơ của bạn và bảng thành phần của ${food.name}: Sản phẩm chứa 45% yến mạch cung cấp tinh bột hấp thu chậm, nhưng chứa 18g đường/100g (vượt mức 10g cá nhân). Nếu bạn trong giai đoạn xiết cân, nên cân nhắc dùng loại nguyên bản ít đường hơn.';
    } else if (lower.contains('lecithin') || lower.contains('nhũ hóa')) {
      return 'Chất nhũ hóa Lecithin đậu nành được đánh giá là an toàn thực phẩm. Tuy nhiên, nếu bạn bị dị ứng đậu nành nặng thì nên lưu ý. Với hồ sơ dị ứng sữa của bạn, rủi ro chính nằm ở bột sữa 8%.';
    } else if (lower.contains('trẻ em') || lower.contains('trẻ')) {
      return 'Trẻ em trên 3 tuổi có thể ăn được bánh này. Tuy nhiên, do sản phẩm thuộc nhóm siêu chế biến NOVA 4 và có 18g đường, không nên cho trẻ ăn thường xuyên để tránh dư thừa đường.';
    } else {
      return 'Trợ lý AI Ăn Lành đã phân tích sản phẩm ${food.name}: Dù có 45% yến mạch giàu chất xơ, sản phẩm chứa bột sữa 8% (trùng dị ứng của bạn) và thuộc nhóm NOVA 4. Bạn có thể xem gợi ý các sản phẩm ít đường và không có sữa thay thế.';
    }
  }

  void _sendMessage() {
    final query = _textController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _messages.add({'sender': 'user', 'text': query});
      _messages.add(
          {'sender': 'ai', 'text': _generateAiResponse(query, widget.food)});
      _textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFE8F2E7),
                  child:
                      Icon(Icons.auto_awesome, color: primaryGreen, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Trợ lý AI Ăn Lành',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: inkText)),
                      Text('Đang hỏi đáp về: ${widget.food.name}',
                          style:
                              const TextStyle(fontSize: 11, color: subText)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: subText),
                )
              ],
            ),
            const Divider(height: 20),

            // Messages List
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (ctx, idx) {
                  final msg = _messages[idx];
                  final isUser = msg['sender'] == 'user';
                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(14),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78,
                      ),
                      decoration: BoxDecoration(
                        color: isUser
                            ? primaryGreen
                            : const Color(0xFFE8F2E7),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isUser ? 16 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 16),
                        ),
                      ),
                      child: Text(
                        msg['text'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: isUser ? Colors.white : inkText,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Input Bar
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Nhập câu hỏi bất kỳ cho AI...',
                        hintStyle:
                            const TextStyle(fontSize: 12, color: subText),
                        filled: true,
                        fillColor: const Color(0xFFF4F6F3),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: primaryGreen),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: primaryGreen,
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

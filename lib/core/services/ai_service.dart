import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../business_logic/rules/ai_note_parser.dart';

class AiServiceResult {
  final List<ExtractedCriterion> criteria;
  final bool isFromCloudAi;
  final String providerName;

  AiServiceResult({
    required this.criteria,
    required this.isFromCloudAi,
    required this.providerName,
  });
}

class AiService {
  static const String _defaultModel = 'gemini-2.5-flash';
  static String? userApiKey; // Secured: No hardcoded API key in repo

  static String get activeApiKey {
    if (userApiKey != null && userApiKey!.trim().isNotEmpty) {
      return userApiKey!.trim();
    }
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    return envKey;
  }

  static Future<AiServiceResult> analyzeNote(
    String noteText, {
    bool aiConsent = true,
    http.Client? client,
    String? customApiKey,
  }) async {
    final trimmedNote = noteText.trim();
    if (trimmedNote.isEmpty) {
      return AiServiceResult(
        criteria: [],
        isFromCloudAi: false,
        providerName: 'Không có nội dung',
      );
    }

    final key = (customApiKey != null && customApiKey.trim().isNotEmpty)
        ? customApiKey.trim()
        : activeApiKey;

    // Privacy Protection: If user did NOT consent to cloud AI sharing, or no API key, use Offline Rule Parser
    if (!aiConsent || key.isEmpty) {
      final localCriteria = AiNoteParser.parse(trimmedNote);
      return AiServiceResult(
        criteria: localCriteria,
        isFromCloudAi: false,
        providerName: 'Phân tích tự động (Offline)',
      );
    }

    final httpClient = client ?? http.Client();
    try {
      final endpoint = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_defaultModel:generateContent?key=$key',
      );

      final prompt = '''
Bạn là chuyên gia phân tích dị ứng và tiêu chuẩn dinh dưỡng thực phẩm.
Phân tích ghi chú người dùng sau: "$trimmedNote"

Hãy trả về duy nhất chuỗi JSON hợp lệ (không kèm markdown ```) theo cấu trúc:
{
  "allergens": [
    {
      "key": "mã_dị_ứng_ngắn_gọn (vd: milk, peanut, orange, apple, shrimp, egg, seafood...)",
      "title": "Tên chất dị ứng",
      "quote": "từ trích dẫn nguyên văn trong ghi chú"
    }
  ],
  "nutrition": [
    {
      "key": "mã_chỉ_số (vd: sugars, sodium, total_fat, protein_min, calories, fiber)",
      "title": "Tên tiêu chí dinh dưỡng / mục tiêu",
      "limit": số_thực_ngưỡng_gợi_ý,
      "quote": "từ trích dẫn nguyên văn trong ghi chú"
    }
  ]
}
Nếu ghi chú không chứa tiêu chí ăn uống/dị ứng/dinh dưỡng nào, trả về: {"allergens": [], "nutrition": []}.
''';

      final response = await httpClient
          .post(
            endpoint,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.1,
                'responseMimeType': 'application/json',
              }
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final candidates = body['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates.first['content'];
          final parts = content?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final rawText = parts.first['text'] as String?;
            if (rawText != null && rawText.trim().isNotEmpty) {
              final parsedCriteria = _parseGeminiJson(rawText.trim());
              return AiServiceResult(
                criteria: parsedCriteria,
                isFromCloudAi: true,
                providerName: 'Google Gemini 2.5 Flash',
              );
            }
          }
        }
      }
    } catch (_) {
      // Fallback smoothly on network error, timeout, or invalid API key
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }

    final localCriteria = AiNoteParser.parse(trimmedNote);
    return AiServiceResult(
      criteria: localCriteria,
      isFromCloudAi: false,
      providerName: 'Phân tích tự động (Offline)',
    );
  }

  static List<ExtractedCriterion> _parseGeminiJson(String jsonText) {
    try {
      var clean = jsonText.trim();
      if (clean.startsWith('```json')) {
        clean = clean.substring(7);
      }
      if (clean.startsWith('```')) {
        clean = clean.substring(3);
      }
      if (clean.endsWith('```')) {
        clean = clean.substring(0, clean.length - 3);
      }
      clean = clean.trim();

      final data = jsonDecode(clean);
      final List<ExtractedCriterion> list = [];

      if (data is Map) {
        if (data['allergens'] is List) {
          for (final a in data['allergens']) {
            if (a is Map) {
              final key = a['key']?.toString().toLowerCase().trim() ?? '';
              final title = a['title']?.toString() ?? 'Dị ứng $key';
              final quote = a['quote']?.toString() ?? key;
              if (key.isNotEmpty) {
                list.add(ExtractedCriterion(
                  id: 'allergen_$key',
                  title: title,
                  subtitle: 'Gợi ý từ Gemini AI · Tránh $title',
                  quote: quote,
                  type: 'allergen',
                  allergenKey: key,
                ));
              }
            }
          }
        }

        if (data['nutrition'] is List) {
          for (final n in data['nutrition']) {
            if (n is Map) {
              final key = n['key']?.toString().toLowerCase().trim() ?? '';
              final title = n['title']?.toString() ?? 'Chỉ số $key';
              final limit = (n['limit'] as num?)?.toDouble() ?? 10.0;
              final quote = n['quote']?.toString() ?? key;
              if (key.isNotEmpty) {
                list.add(ExtractedCriterion(
                  id: 'nutrition_$key',
                  title: title,
                  subtitle: 'Mức Gemini AI gợi ý: ≤ $limit',
                  quote: quote,
                  type: 'nutrition',
                  nutritionKey: key,
                  targetValue: limit,
                ));
              }
            }
          }
        }
      }
      return list;
    } catch (_) {
      return [];
    }
  }
}

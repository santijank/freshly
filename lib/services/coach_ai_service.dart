import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/health_store.dart';

class CoachAiService {
  static const _apiKey = String.fromEnvironment('GROQ_API_KEY');
  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'llama-3.3-70b-versatile';

  static const _systemPromptTemplate = '''
You are Nourish AI Coach — a friendly Thai health and nutrition advisor.
You have access to the user's data:
{context}

Rules:
- Always respond in Thai
- Be encouraging and specific
- Give practical actionable advice
- Reference their actual food data when relevant
- Keep responses concise (2-4 sentences unless meal plan requested)
''';

  /// Build additional lab context string from the latest lab report.
  String _buildLabContext() {
    final latestReport = HealthStore.instance.latestReport;
    if (latestReport == null) return '';
    final buf = StringBuffer();
    buf.write('\n\nผลตรวจร่างกายล่าสุด (${latestReport.date.day}/${latestReport.date.month}/${latestReport.date.year}):\n');
    for (final m in latestReport.metrics) {
      buf.write('${m.nameThai}: ${m.value.toStringAsFixed(1)} ${m.unit} (${m.statusLabel})\n');
    }
    return buf.toString();
  }

  Future<String> sendMessage(
    String message, {
    required String context,
  }) async {
    final fullContext = context + _buildLabContext();
    final systemPrompt =
        _systemPromptTemplate.replaceFirst('{context}', fullContext);

    final body = jsonEncode({
      'model': _model,
      'messages': [
        {
          'role': 'system',
          'content': systemPrompt,
        },
        {
          'role': 'user',
          'content': message,
        },
      ],
      'temperature': 0.7,
      'max_tokens': 1024,
    });

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Groq coach API error: ${response.statusCode} ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content =
        (decoded['choices'] as List).first['message']['content'] as String;
    return content.trim();
  }

  /// Generate a daily tip based on today's nutrition data.
  Future<String> generateDailyTip({required String context}) async {
    return sendMessage(
      'สรุปสั้นๆ ว่าวันนี้ฉันกินอาหารเป็นอย่างไรบ้าง และให้คำแนะนำ 1 ข้อสำหรับมื้อต่อไป',
      context: context,
    );
  }

  /// Generate a weekly insight based on weekly nutrition summary.
  Future<String> generateWeeklyInsight({required String context}) async {
    return sendMessage(
      'วิเคราะห์ข้อมูลการกินอาหารของฉันสัปดาห์นี้ และให้คำแนะนำสำหรับสัปดาห์หน้า',
      context: context,
    );
  }
}

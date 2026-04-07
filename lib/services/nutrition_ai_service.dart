import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/meal_log.dart';

class NutritionAiService {
  static const _apiKey = '__GROQ_API_KEY__';
  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const _visionModel = 'meta-llama/llama-4-scout-17b-16e-instruct';
  static const _textModel = 'llama-3.1-8b-instant';

  static const _imageSystemPrompt = '''
You are a nutrition expert. Analyze food images and return accurate nutrition estimates.
Always respond with valid JSON only — no markdown fences, no extra text.
''';

  static const _imageUserPrompt = '''
Analyze this food image. Identify all food items and estimate their nutrition.
Return ONLY valid JSON:
{
  "items": [
    {
      "name": "ชื่ออาหารภาษาไทย",
      "emoji": "🍚",
      "quantity": "1 จาน (~200g)",
      "calories": 350,
      "protein": 12.5,
      "carbs": 60.0,
      "fat": 8.0
    }
  ]
}
Rules: Thai names, realistic portion estimates, no markdown fences.
''';

  static const _textSystemPrompt = '''
You are a nutrition expert. Estimate nutrition for food items described in Thai or English.
Always respond with valid JSON only — no markdown fences, no extra text.
''';

  /// Analyze a food image using Groq LLaMA 4 Scout vision model.
  Future<List<MealItem>> analyzeImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final ext = imageFile.path.split('.').last.toLowerCase();
    final mime = switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final body = jsonEncode({
      'model': _visionModel,
      'messages': [
        {
          'role': 'system',
          'content': _imageSystemPrompt,
        },
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': _imageUserPrompt},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:$mime;base64,$base64Image'},
            },
          ],
        }
      ],
      'temperature': 0.1,
      'max_tokens': 2048,
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
      throw Exception('Groq vision API error: ${response.statusCode} ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content =
        (decoded['choices'] as List).first['message']['content'] as String;

    return _parseItems(content);
  }

  /// Analyze a text description — auto-retry up to 3 times on 429.
  Future<List<MealItem>> analyzeText(String description) async {
    final userPrompt =
        'Food: $description\nReturn ONLY JSON: {"items":[{"name":"ชื่อไทย","emoji":"🍚","quantity":"1 จาน","calories":0,"protein":0,"carbs":0,"fat":0}]}';

    final body = jsonEncode({
      'model': _textModel,
      'messages': [
        {'role': 'system', 'content': 'Nutrition expert. Return valid JSON only, no markdown.'},
        {'role': 'user', 'content': userPrompt},
      ],
      'temperature': 0.1,
      'max_tokens': 512,
    });

    const maxRetries = 3;
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final content =
            (decoded['choices'] as List).first['message']['content'] as String;
        return _parseItems(content);
      }

      if (response.statusCode == 429 && attempt < maxRetries - 1) {
        // Rate limited — wait and retry
        await Future.delayed(Duration(seconds: 3 * (attempt + 1)));
        continue;
      }

      throw Exception('Groq text API error: ${response.statusCode} ${response.body}');
    }
    throw Exception('Groq text API error: 429 exceeded retries');
  }

  List<MealItem> _parseItems(String content) {
    String cleaned = content.trim();
    // Always extract the outermost { ... } regardless of surrounding text
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      cleaned = cleaned.substring(start, end + 1);
    }

    final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
    final itemsJson = parsed['items'] as List<dynamic>;

    int counter = DateTime.now().millisecondsSinceEpoch;
    return itemsJson.map((item) {
      final map = item as Map<String, dynamic>;
      return MealItem(
        id: '${counter++}',
        name: map['name'] as String? ?? 'อาหาร',
        emoji: map['emoji'] as String? ?? '🍽️',
        quantity: map['quantity'] as String? ?? '1 จาน',
        nutrition: FoodNutrition(
          calories: (map['calories'] as num?)?.toDouble() ?? 0,
          protein: (map['protein'] as num?)?.toDouble() ?? 0,
          carbs: (map['carbs'] as num?)?.toDouble() ?? 0,
          fat: (map['fat'] as num?)?.toDouble() ?? 0,
        ),
      );
    }).toList();
  }
}

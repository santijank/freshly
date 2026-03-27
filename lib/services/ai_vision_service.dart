import 'dart:convert';
import 'dart:io';
import '../models/scan_result.dart';

/// Contract for any AI vision backend.
abstract class AiVisionService {
  /// Analyse [imageFile] and return detected food items.
  Future<ScanResult> analyzeImage(File imageFile);
}

// ─────────────────────────────────────────────
// Shared prompt & JSON parsing utilities
// ─────────────────────────────────────────────

/// System role — sets the AI persona
const String kFoodAnalysisSystemPrompt =
    'You are an expert food identification AI specializing in refrigerator and food storage analysis. '
    'Your ONLY job is to identify FOOD and BEVERAGES — items that humans eat or drink. '
    'You MUST ignore all non-food objects. You respond only in valid JSON format.';

/// User prompt sent with the image
const String kFoodAnalysisPrompt = '''
Examine this image and identify ONLY food and beverage items.

STRICT FOOD-ONLY RULES:
1. ✅ INCLUDE: fresh produce, meat, dairy, eggs, beverages, sauces, condiments, packaged food, cooked food, snacks
2. ❌ EXCLUDE: cleaning products, medicine, cosmetics, utensils, containers (unless they contain food), paper, keys, phones, or any non-edible object
3. If an item is uncertain whether it is food → set "is_food": false and skip it
4. For food items: ALWAYS give your best guess by color/shape/packaging (e.g. "ขวดซอสสีแดง", "ถุงผักสีเขียว")
5. Only use "ไม่แน่ใจ" for food items you cannot identify clearly
6. Food names MUST be in Thai language

Return ONLY this JSON — no markdown, no explanation:

{
  "items": [
    {
      "name": "<ชื่ออาหาร/เครื่องดื่มภาษาไทย>",
      "is_food": true,
      "quantity": "<ปริมาณที่เห็น เช่น '~300g', 'ครึ่งขวด', '3 ชิ้น'>",
      "estimated_expiry": "<ISO-8601 หรือ '3 วัน' หรือ '1 สัปดาห์' — ละไว้ถ้าไม่ทราบ>",
      "confidence": <0.0–1.0>,
      "note": "<หมายเหตุสั้นๆ ถ้ามี>"
    }
  ]
}
''';

/// Parse the raw string from the AI into a [ScanResult].
ScanResult parseAiResponse(String raw) {
  // Strip markdown fences if the model ignores the instruction
  var cleaned = raw.trim();
  if (cleaned.startsWith('```')) {
    cleaned = cleaned
        .replaceFirst(RegExp(r'^```[a-z]*\n?'), '')
        .replaceFirst(RegExp(r'\n?```$'), '')
        .trim();
  }

  final Map<String, dynamic> jsonMap;
  try {
    jsonMap = json.decode(cleaned) as Map<String, dynamic>;
  } catch (e) {
    return ScanResult.failure('JSON parse error: $e\nRaw: $raw');
  }

  final rawItems = jsonMap['items'];
  if (rawItems is! List) {
    return ScanResult.failure('Unexpected JSON shape: missing "items" array.');
  }

  final items = rawItems
      .whereType<Map<String, dynamic>>()
      .where((e) => e['is_food'] != false) // กรองเฉพาะอาหาร
      .map(DetectedFoodItem.fromJson)
      .toList();

  return ScanResult(
    items: items,
    success: true,
    rawResponse: raw,
  );
}

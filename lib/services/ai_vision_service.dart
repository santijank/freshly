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
    'You are an expert food identification AI with deep knowledge of Thai and international foods. '
    'You have excellent vision and can identify food items even in poor lighting, partial views, or blurry images. '
    'You ALWAYS make your best identification attempt — you never give up. '
    'You respond only in valid JSON format.';

/// User prompt sent with the image
const String kFoodAnalysisPrompt = '''
Carefully examine this image and identify EVERY visible food item.

IMPORTANT RULES:
1. ALWAYS give your best guess — even if unsure, describe by color/shape/packaging (e.g. "ขวดซอสสีแดง", "ถุงผักสีเขียว")
2. Only use "ไม่แน่ใจ" when you truly cannot distinguish food from non-food
3. For packaged items: read labels, logos, or describe the packaging
4. For fresh produce: identify by shape, color, texture
5. Food names MUST be in Thai language
6. Include partially visible items

Return ONLY this JSON — no markdown, no explanation:

{
  "items": [
    {
      "name": "<ชื่ออาหารภาษาไทย — ถ้าไม่แน่ใจให้อธิบายลักษณะ เช่น 'ผักสีเขียวคล้ายผักชี'>",
      "quantity": "<ปริมาณที่เห็น เช่น '~300g', 'ครึ่งขวด', '3 ชิ้น'>",
      "estimated_expiry": "<วันหมดอายุ ISO-8601 หรือ '3 วัน' หรือ '1 สัปดาห์' — ละไว้ถ้าไม่ทราบ>",
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
      .map(DetectedFoodItem.fromJson)
      .toList();

  return ScanResult(
    items: items,
    success: true,
    rawResponse: raw,
  );
}

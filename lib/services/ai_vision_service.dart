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

/// The system prompt sent to every AI backend.
const String kFoodAnalysisPrompt = '''
You are a food freshness expert and computer vision assistant embedded in an
eco-friendly food-tracking mobile app called "Freshly".

Analyze the image provided and identify every visible food item.

Return ONLY a valid JSON object in this exact schema — no markdown, no extra text:

{
  "items": [
    {
      "name": "<food name in Thai, or 'ไม่แน่ใจ' if you cannot identify it>",
      "quantity": "<remaining quantity, e.g. '~300g', 'half full', '3 pieces'>",
      "estimated_expiry": "<ISO-8601 date OR relative like '3 days' OR '1 week' — omit field if unknown>",
      "confidence": <float 0.0–1.0>,
      "note": "<optional short note, e.g. 'Could be broccoli or kale'>"
    }
  ]
}

Rules:
- Set "name" to "ไม่แน่ใจ" when confidence < 0.5 or you cannot identify the item.
- Always respond with food names in Thai language.
- Always include every visible food item, even partially visible ones.
- For packaged goods, try to read the label; if unreadable, note it.
- Do NOT include plates, cutlery, containers, or non-food objects.
- Do NOT wrap the JSON in code fences.
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

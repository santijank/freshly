/// Represents a single food item detected by the AI vision service.
class DetectedFoodItem {
  /// Display name of the food (e.g. "Spinach", "Greek Yogurt").
  /// Will be "Uncertain" when AI confidence is too low.
  final String name;

  /// Human-readable remaining quantity (e.g. "half full", "2 pieces", "~300g").
  final String quantity;

  /// AI-estimated expiry date. Null when AI cannot determine.
  final DateTime? estimatedExpiry;

  /// Confidence score 0.0–1.0 from the AI model.
  final double confidence;

  /// True when AI cannot identify the item and user input is required.
  final bool isUncertain;

  /// Short note from AI (e.g. "Could be broccoli or kale").
  final String? note;

  const DetectedFoodItem({
    required this.name,
    required this.quantity,
    required this.estimatedExpiry,
    required this.confidence,
    required this.isUncertain,
    this.note,
  });

  /// Parse from the JSON object returned by the AI.
  factory DetectedFoodItem.fromJson(Map<String, dynamic> json) {
    final rawName = (json['name'] as String?)?.trim() ?? 'ไม่แน่ใจ';
    final confidence = (json['confidence'] as num?)?.toDouble() ?? 1.0;
    final isUncertain =
        rawName.toLowerCase() == 'uncertain' ||
        rawName == 'ไม่แน่ใจ' ||
        rawName.isEmpty ||
        confidence < 0.3;

    DateTime? expiry;
    final expiryStr = json['estimated_expiry'] as String?;
    if (expiryStr != null && expiryStr.isNotEmpty) {
      expiry = _parseExpiry(expiryStr);
    }

    return DetectedFoodItem(
      name: isUncertain ? 'ไม่แน่ใจ' : rawName,
      quantity: (json['quantity'] as String?)?.trim() ?? 'ไม่ทราบ',
      estimatedExpiry: expiry,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      isUncertain: isUncertain,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'estimated_expiry': estimatedExpiry?.toIso8601String(),
        'confidence': confidence,
        'is_uncertain': isUncertain,
        'note': note,
      };

  /// Tries several date formats from the AI output.
  static DateTime? _parseExpiry(String raw) {
    // ISO-8601
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso;

    // Relative: "3 days", "1 week", "2 weeks", "1 month"
    final relative = RegExp(
      r'^(\d+)\s*(day|week|month)s?$',
      caseSensitive: false,
    ).firstMatch(raw.trim());
    if (relative != null) {
      final n = int.parse(relative.group(1)!);
      final unit = relative.group(2)!.toLowerCase();
      final now = DateTime.now();
      return switch (unit) {
        'day' => now.add(Duration(days: n)),
        'week' => now.add(Duration(days: n * 7)),
        'month' => DateTime(now.year, now.month + n, now.day),
        _ => null,
      };
    }
    return null;
  }

  int get daysUntilExpiry =>
      estimatedExpiry?.difference(DateTime.now()).inDays ?? 0;
}

/// The full result returned after one AI scan call.
class ScanResult {
  final List<DetectedFoodItem> items;

  /// True when the API call or JSON parsing succeeded.
  final bool success;

  /// Human-readable error message when [success] is false.
  final String? errorMessage;

  /// Raw JSON string from the AI (for debugging).
  final String? rawResponse;

  const ScanResult({
    required this.items,
    required this.success,
    this.errorMessage,
    this.rawResponse,
  });

  factory ScanResult.failure(String message) => ScanResult(
        items: const [],
        success: false,
        errorMessage: message,
      );

  /// Items that need user confirmation.
  List<DetectedFoodItem> get uncertainItems =>
      items.where((i) => i.isUncertain).toList();

  /// Items the AI identified with confidence.
  List<DetectedFoodItem> get confirmedItems =>
      items.where((i) => !i.isUncertain).toList();
}

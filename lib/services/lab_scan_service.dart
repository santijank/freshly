import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/health_metrics.dart';
import '../models/user_profile.dart';

class LabScanService {
  static const _apiKey = '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';
  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const _visionModel = 'meta-llama/llama-4-scout-17b-16e-instruct';
  static const _textModel = 'llama-3.3-70b-versatile';

  static const _labPrompt = '''
You are a medical lab report analyzer. Carefully read this blood test / health checkup report image.

Extract ALL test values visible in the image. Return ONLY valid JSON — no markdown:

{
  "lab_name": "hospital or clinic name if visible, or null",
  "report_date": "YYYY-MM-DD if visible, or null",
  "metrics": [
    {
      "name": "English metric name",
      "name_thai": "ชื่อภาษาไทย",
      "value": 210.5,
      "unit": "mg/dL",
      "normal_min": 0,
      "normal_max": 200,
      "status": "high",
      "category": "lipid"
    }
  ]
}

Common metrics to look for:
- Blood Sugar: Fasting Blood Sugar (FBS/น้ำตาลในเลือด), HbA1c
- Lipids: Total Cholesterol (โคเลสเตอรอลรวม), LDL, HDL, Triglycerides (ไตรกลีเซอไรด์)
- Blood Count: Hemoglobin (ฮีโมโกลบิน), Hematocrit, WBC, RBC, Platelets
- Liver: ALT/SGPT, AST/SGOT, Alkaline Phosphatase
- Kidney: Creatinine (ครีเอตินิน), BUN, eGFR, Uric Acid (กรดยูริก)
- Thyroid: TSH, T3, T4

Status rules:
- "normal": within normal range shown on report
- "high": above normal max
- "low": below normal min
- "borderline": slightly above/below (within 10% of limit)

Category values: "bloodSugar", "lipid", "bloodCount", "liver", "kidney", "thyroid", "other"

If you cannot read a value clearly, skip it. Read Thai text if present.
''';

  /// Analyze a lab report image and return a LabReport.
  Future<LabReport> analyzeLabImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final body = jsonEncode({
      'model': _visionModel,
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': _labPrompt},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
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
      final errBody = jsonDecode(response.body);
      throw Exception(
          errBody['error']?['message'] ?? 'Lab scan API error: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content =
        (decoded['choices'] as List).first['message']['content'] as String;

    return _parseLabResponse(content, imageFile.path);
  }

  LabReport _parseLabResponse(String raw, String imagePath) {
    var cleaned = raw.trim();
    // Strip markdown code fences if present
    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst(RegExp(r'^```[a-z]*\n?'), '')
          .replaceFirst(RegExp(r'\n?```$'), '')
          .trim();
    }

    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      // Try to extract JSON from within text
      final jsonMatch = RegExp(r'\{[\s\S]+\}').firstMatch(cleaned);
      if (jsonMatch != null) {
        try {
          parsed = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
        } catch (_) {
          parsed = {};
        }
      } else {
        parsed = {};
      }
    }

    final rawMetrics = parsed['metrics'] as List? ?? [];
    final metrics = rawMetrics
        .whereType<Map<String, dynamic>>()
        .map(HealthMetric.fromJson)
        .toList();

    DateTime reportDate = DateTime.now();
    final dateStr = parsed['report_date'] as String?;
    if (dateStr != null) {
      try {
        reportDate = DateTime.parse(dateStr);
      } catch (_) {
        // use today
      }
    }

    return LabReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: reportDate,
      imagePath: imagePath,
      metrics: metrics,
      labName: parsed['lab_name'] as String?,
    );
  }

  /// Generate a personalized dietary plan based on the lab report.
  Future<String> generateDietaryPlan(
      LabReport report, UserProfile? profile) async {
    final metricsText = report.metrics
        .map((m) =>
            '${m.nameThai}: ${m.value.toStringAsFixed(1)} ${m.unit} (${m.statusLabel})')
        .join('\n');

    String profileText = '';
    if (profile != null) {
      profileText = '''
ข้อมูลผู้ใช้:
- ชื่อ: ${profile.name}
- อายุ: ${profile.age} ปี
- เพศ: ${profile.gender == 'male' ? 'ชาย' : 'หญิง'}
- น้ำหนัก: ${profile.weightKg.toStringAsFixed(1)} กก.
- ส่วนสูง: ${profile.heightCm.toStringAsFixed(0)} ซม.
- เป้าหมาย: ${profile.goalLabel}
''';
    }

    final prompt = '''
คุณเป็นนักโภชนาการและแพทย์ที่เชี่ยวชาญด้านอาหารสุขภาพ

ผลตรวจร่างกายของผู้ใช้:
$metricsText

$profileText
กรุณาวางแผนอาหารส่วนตัวเป็นภาษาไทย โดยครอบคลุม:

1. 🔍 **สรุปผลตรวจ** — ค่าที่ผิดปกติและความหมาย
2. ⛔ **อาหารที่ควรหลีกเลี่ยง** — ระบุเหตุผลจากผลเลือด
3. ✅ **อาหารที่ควรเพิ่ม** — ระบุเหตุผลและประโยชน์
4. 🍽️ **ตัวอย่างเมนูอาหาร 3 มื้อ** สำหรับ 1 วัน
5. 💡 **คำแนะนำเพิ่มเติม** — ไลฟ์สไตล์ การออกกำลังกาย

ตอบให้ชัดเจน เข้าใจง่าย และเป็นประโยชน์จริง
''';

    final body = jsonEncode({
      'model': _textModel,
      'messages': [
        {
          'role': 'user',
          'content': prompt,
        }
      ],
      'temperature': 0.6,
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
      final errBody = jsonDecode(response.body);
      throw Exception(
          errBody['error']?['message'] ?? 'Dietary plan API error: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content =
        (decoded['choices'] as List).first['message']['content'] as String;
    return content.trim();
  }
}

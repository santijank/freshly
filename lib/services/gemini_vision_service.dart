import 'dart:io';
import '../models/scan_result.dart';
import 'ai_vision_service.dart';

/// Gemini vision service — disabled (google_generative_ai package removed).
/// App now uses GroqVisionService instead.
class GeminiVisionService implements AiVisionService {
  GeminiVisionService({required String apiKey});

  @override
  Future<ScanResult> analyzeImage(File imageFile) async {
    return ScanResult.failure('Gemini service is disabled. Use GroqVisionService instead.');
  }
}

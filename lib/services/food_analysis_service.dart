import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/scan_result.dart';
import 'ai_vision_service.dart';
import 'gemini_vision_service.dart';
import 'openai_vision_service.dart';

enum AiProvider { gemini, openai }

/// High-level orchestrator:
/// - Picks the configured AI backend
/// - Calls the vision service
/// - Handles fallback when primary fails
/// - Separates confirmed vs. uncertain items for the UI
class FoodAnalysisService {
  late final AiVisionService _primary;
  AiVisionService? _fallback;

  FoodAnalysisService({AiProvider provider = AiProvider.gemini}) {
    _primary = _buildService(provider);

    // Automatic fallback to the other provider if both keys are set
    final fallbackProvider =
        provider == AiProvider.gemini ? AiProvider.openai : AiProvider.gemini;
    try {
      _fallback = _buildService(fallbackProvider);
    } catch (_) {
      // Fallback key not configured — that's fine
    }
  }

  static AiVisionService _buildService(AiProvider provider) {
    switch (provider) {
      case AiProvider.gemini:
        final key = dotenv.env['GEMINI_API_KEY'] ?? '';
        if (key.isEmpty || key == 'your_gemini_api_key_here') {
          throw StateError('GEMINI_API_KEY is not configured in .env');
        }
        return GeminiVisionService(apiKey: key);

      case AiProvider.openai:
        final key = dotenv.env['OPENAI_API_KEY'] ?? '';
        if (key.isEmpty || key == 'your_openai_api_key_here') {
          throw StateError('OPENAI_API_KEY is not configured in .env');
        }
        return OpenAiVisionService(apiKey: key);
    }
  }

  /// Analyse [imageFile].
  /// Returns a [ScanResult] which the UI splits into confirmed + uncertain items.
  Future<ScanResult> analyze(File imageFile) async {
    var result = await _primary.analyzeImage(imageFile);

    // Fallback when primary fails but we have a secondary configured
    if (!result.success && _fallback != null) {
      result = await _fallback!.analyzeImage(imageFile);
    }

    return result;
  }
}

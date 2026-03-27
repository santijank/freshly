import 'dart:io';
import '../models/scan_result.dart';
import 'ai_vision_service.dart';
import 'groq_vision_service.dart';

const groqApiKey = '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';

enum AiProvider { groq }

class FoodAnalysisService {
  late final AiVisionService _primary;

  FoodAnalysisService({AiProvider provider = AiProvider.groq}) {
    _primary = GroqVisionService(apiKey: groqApiKey);
  }

  Future<ScanResult> analyze(File imageFile) async {
    return await _primary.analyzeImage(imageFile);
  }
}

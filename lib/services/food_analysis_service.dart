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

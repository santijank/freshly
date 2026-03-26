import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/scan_result.dart';
import 'ai_vision_service.dart';
import 'groq_vision_service.dart';

enum AiProvider { groq }

class FoodAnalysisService {
  late final AiVisionService _primary;

  FoodAnalysisService({AiProvider provider = AiProvider.groq}) {
    _primary = _buildService(provider);
  }

  static AiVisionService _buildService(AiProvider provider) {
    switch (provider) {
      case AiProvider.groq:
        final key = dotenv.env['GROQ_API_KEY'] ?? '';
        if (key.isEmpty) {
          throw StateError('GROQ_API_KEY is not configured in .env');
        }
        return GroqVisionService(apiKey: key);
    }
  }

  Future<ScanResult> analyze(File imageFile) async {
    return await _primary.analyzeImage(imageFile);
  }
}

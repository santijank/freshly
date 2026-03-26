import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/scan_result.dart';
import 'ai_vision_service.dart';

/// Uses Google Gemini 1.5 Flash to analyse food images.
///
/// Obtain an API key at https://aistudio.google.com/app/apikey
class GeminiVisionService implements AiVisionService {
  final GenerativeModel _model;

  GeminiVisionService({required String apiKey})
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash-latest',
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            // Keep responses deterministic and compact
            temperature: 0.2,
            topP: 0.8,
            maxOutputTokens: 2048,
          ),
          safetySettings: [
            SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
            SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
          ],
        );

  @override
  Future<ScanResult> analyzeImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();

    // Determine MIME type from extension
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mime = switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final content = Content.multi([
      TextPart(kFoodAnalysisPrompt),
      DataPart(mime, bytes),
    ]);

    try {
      final response = await _model.generateContent([content]);
      final text = response.text;

      if (text == null || text.isEmpty) {
        return ScanResult.failure('Gemini returned an empty response.');
      }

      return parseAiResponse(text);
    } on GenerativeAIException catch (e) {
      return ScanResult.failure('Gemini API error: ${e.message}');
    } catch (e) {
      return ScanResult.failure('Unexpected error: $e');
    }
  }
}

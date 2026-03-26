import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/scan_result.dart';
import 'ai_vision_service.dart';

class GroqVisionService implements AiVisionService {
  final String _apiKey;
  static const _model = 'meta-llama/llama-4-scout-17b-16e-instruct';
  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  GroqVisionService({required String apiKey}) : _apiKey = apiKey;

  @override
  Future<ScanResult> analyzeImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final ext = imageFile.path.split('.').last.toLowerCase();
    final mime = switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final body = jsonEncode({
      'model': _model,
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': kFoodAnalysisPrompt},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:$mime;base64,$base64Image'},
            },
          ],
        }
      ],
      'temperature': 0.2,
      'max_tokens': 2048,
    });

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        final err = jsonDecode(response.body);
        return ScanResult.failure(
            'Groq API error: ${err['error']?['message'] ?? response.body}');
      }

      final json = jsonDecode(response.body);
      final text = json['choices']?[0]?['message']?['content'] as String?;

      if (text == null || text.isEmpty) {
        return ScanResult.failure('Groq returned an empty response.');
      }

      return parseAiResponse(text);
    } catch (e) {
      return ScanResult.failure('Unexpected error: $e');
    }
  }
}

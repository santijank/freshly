import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/scan_result.dart';
import 'ai_vision_service.dart';

/// Uses OpenAI GPT-4o vision to analyse food images.
///
/// Obtain an API key at https://platform.openai.com/api-keys
class OpenAiVisionService implements AiVisionService {
  final String _apiKey;
  final String _model;

  static const String _endpoint =
      'https://api.openai.com/v1/chat/completions';

  OpenAiVisionService({
    required String apiKey,
    String model = 'gpt-4o',
  })  : _apiKey = apiKey,
        _model = model;

  @override
  Future<ScanResult> analyzeImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final ext = imageFile.path.split('.').last.toLowerCase();
    final mime = (ext == 'png') ? 'image/png' : 'image/jpeg';

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 2048,
      'temperature': 0.2,
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
        },
      ],
    });

    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final err = jsonDecode(response.body);
        final msg = err['error']?['message'] ?? response.body;
        return ScanResult.failure('OpenAI error ${response.statusCode}: $msg');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final text =
          decoded['choices']?[0]?['message']?['content'] as String? ?? '';

      if (text.isEmpty) {
        return ScanResult.failure('OpenAI returned an empty response.');
      }

      return parseAiResponse(text);
    } on http.ClientException catch (e) {
      return ScanResult.failure('Network error: ${e.message}');
    } catch (e) {
      return ScanResult.failure('Unexpected error: $e');
    }
  }
}

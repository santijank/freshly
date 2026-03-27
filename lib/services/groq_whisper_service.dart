import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'food_analysis_service.dart';

class GroqWhisperService {
  static const _endpoint =
      'https://api.groq.com/openai/v1/audio/transcriptions';

  final Record _recorder = Record();
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  /// เริ่มอัดเสียง — คืน false ถ้า permission ไม่ผ่าน
  Future<bool> startRecording() async {
    if (!await _recorder.hasPermission()) return false;

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_input.m4a';

    await _recorder.start(
      path: path,
      encoder: AudioEncoder.aacLc,
      bitRate: 128000,
      samplingRate: 44100,
    );
    _isRecording = true;
    return true;
  }

  /// หยุดอัด แล้วส่งไป Groq Whisper — คืนข้อความที่ได้
  Future<String?> stopAndTranscribe() async {
    if (!_isRecording) return null;
    final path = await _recorder.stop();
    _isRecording = false;

    if (path == null || !File(path).existsSync()) return null;

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(_endpoint),
      );
      request.headers['Authorization'] = 'Bearer $groqApiKey';
      request.files.add(await http.MultipartFile.fromPath('file', path));
      request.fields['model'] = 'whisper-large-v3-turbo';
      request.fields['language'] = 'th';
      request.fields['response_format'] = 'json';

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200) {
        final json = jsonDecode(body);
        return (json['text'] as String?)?.trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}

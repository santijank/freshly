import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/fridge_store.dart';
import '../theme/app_theme.dart';

const _groqApiKey = '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';
const _groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
const _model = 'meta-llama/llama-4-scout-17b-16e-instruct';

const _receiptPrompt = '''
You are a receipt analyzer embedded in a Thai food-tracking app.
Look at this receipt image and identify all food and beverage items purchased.

Return ONLY valid JSON — no markdown, no extra text:
{
  "items": [
    {
      "name": "<ชื่อสินค้าภาษาไทย>",
      "quantity": "<จำนวน เช่น 1 ชิ้น, 2 กก.>",
      "emoji": "<emoji ที่เหมาะสม>",
      "estimated_expiry_days": <จำนวนวันที่คาดว่าจะหมดอายุ เช่น 7>
    }
  ]
}

Rules:
- Only include food and beverage items
- Translate product names to Thai
- Skip non-food items (bags, packaging, cleaning products etc.)
- If you cannot identify an item as food, skip it
- Do NOT wrap in code fences
''';

class ReceiptScanScreen extends StatefulWidget {
  final CameraDescription camera;
  const ReceiptScanScreen({super.key, required this.camera});

  @override
  State<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends State<ReceiptScanScreen> {
  late CameraController _controller;
  late Future<void> _initFuture;
  bool _analyzing = false;
  String _status = 'ถ่ายรูปใบเสร็จ';

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_analyzing) return;
    setState(() {
      _analyzing = true;
      _status = 'กำลังวิเคราะห์ใบเสร็จ...';
    });

    try {
      final xFile = await _controller.takePicture();
      final imageFile = File(xFile.path);
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final body = jsonEncode({
        'model': _model,
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': _receiptPrompt},
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
              },
            ],
          }
        ],
        'temperature': 0.1,
        'max_tokens': 1024,
      });

      final response = await http.post(
        Uri.parse(_groqEndpoint),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        final err = jsonDecode(response.body);
        throw Exception(err['error']?['message'] ?? response.body);
      }

      final json = jsonDecode(response.body);
      final text = json['choices']?[0]?['message']?['content'] as String?;
      if (text == null || text.isEmpty) throw Exception('ไม่ได้รับข้อมูล');

      final parsed = _parseReceiptResponse(text);
      if (!mounted) return;

      if (parsed.isEmpty) {
        setState(() {
          _analyzing = false;
          _status = 'ไม่พบรายการอาหารในใบเสร็จ ลองใหม่';
        });
        return;
      }

      await _showResultSheet(parsed);
    } catch (e) {
      setState(() {
        _analyzing = false;
        _status = 'เกิดข้อผิดพลาด: $e';
      });
    }
  }

  List<_ReceiptItem> _parseReceiptResponse(String raw) {
    var cleaned = raw.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceFirst(RegExp(r'^```[a-z]*\n?'), '')
          .replaceFirst(RegExp(r'\n?```$'), '')
          .trim();
    }
    try {
      final map = jsonDecode(cleaned) as Map<String, dynamic>;
      final rawItems = map['items'] as List?;
      if (rawItems == null) return [];
      return rawItems
          .whereType<Map<String, dynamic>>()
          .map((i) => _ReceiptItem(
                name: i['name'] as String? ?? 'ไม่ทราบ',
                quantity: i['quantity'] as String? ?? '1 ชิ้น',
                emoji: i['emoji'] as String? ?? '🍽️',
                expiryDays: i['estimated_expiry_days'] as int? ?? 7,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _showResultSheet(List<_ReceiptItem> items) async {
    final selected = await showModalBottomSheet<List<_ReceiptItem>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ReceiptResultSheet(items: items),
    );

    if (!mounted) return;
    setState(() {
      _analyzing = false;
      _status = 'ถ่ายรูปใบเสร็จ';
    });

    if (selected != null && selected.isNotEmpty) {
      for (final item in selected) {
        FridgeStore.instance.addManual(
          item.name,
          expiryDate: DateTime.now().add(Duration(days: item.expiryDays)),
        );
      }
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            children: [
              // Camera preview
              Positioned.fill(child: CameraPreview(_controller)),

              // Top bar
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 22),
                        ),
                      ),
                      const Text(
                        'สแกนใบเสร็จ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
              ),

              // Scan guide overlay
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.height * 0.5,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _analyzing
                          ? Colors.yellow
                          : AppColors.primaryLight,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _analyzing
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.yellow,
                          ),
                        )
                      : null,
                ),
              ),

              // Status + shutter
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          _status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            shadows: [Shadow(blurRadius: 4)],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _analyzing ? null : _capture,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 32),
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _analyzing
                                ? Colors.grey
                                : AppColors.primaryLight,
                            border: Border.all(
                                color: Colors.white, width: 3),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Receipt item data ───────────────────────────────────────

class _ReceiptItem {
  final String name;
  final String quantity;
  final String emoji;
  final int expiryDays;
  bool selected;

  _ReceiptItem({
    required this.name,
    required this.quantity,
    required this.emoji,
    required this.expiryDays,
    this.selected = true,
  });
}

// ── Result sheet ────────────────────────────────────────────

class _ReceiptResultSheet extends StatefulWidget {
  final List<_ReceiptItem> items;
  const _ReceiptResultSheet({required this.items});

  @override
  State<_ReceiptResultSheet> createState() => _ReceiptResultSheetState();
}

class _ReceiptResultSheetState extends State<_ReceiptResultSheet> {
  @override
  Widget build(BuildContext context) {
    final selected = widget.items.where((i) => i.selected).toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('🧾', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'พบ ${widget.items.length} รายการ',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  'เลือก ${selected.length}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'เลือกรายการที่ต้องการเพิ่มเข้าตู้เย็น',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => item.selected = !item.selected),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: item.selected
                            ? AppColors.primary.withOpacity(0.08)
                            : AppColors.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: item.selected
                              ? AppColors.primary.withOpacity(0.3)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(item.emoji,
                              style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  '${item.quantity} · หมดอายุใน ${item.expiryDays} วัน',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            item.selected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: item.selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, null),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('ยกเลิก'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: selected.isEmpty
                        ? null
                        : () => Navigator.pop(context, selected),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'เพิ่ม ${selected.length} รายการ',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

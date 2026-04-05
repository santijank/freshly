import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/fridge_store.dart';
import '../theme/app_theme.dart';

const _groqApiKey = String.fromEnvironment('GROQ_API_KEY');
const _groqModel = 'llama-3.3-70b-versatile';
const _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';

class ShoppingItem {
  final String name;
  final String reason;
  final String category;
  final String emoji;
  bool checked;

  ShoppingItem({
    required this.name,
    required this.reason,
    required this.category,
    required this.emoji,
    this.checked = false,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      name: json['name'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      category: json['category'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '🛒',
    );
  }
}

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  List<ShoppingItem> _items = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  String _buildPrompt() {
    final fridgeItems = FridgeStore.instance.items;
    final buffer = StringBuffer();
    if (fridgeItems.isEmpty) {
      buffer.writeln('ตู้เย็นว่างเปล่า');
    } else {
      for (final item in fridgeItems) {
        final days = item.daysLeft;
        final daysText = days <= 0
            ? 'หมดอายุแล้ว'
            : days == 1
                ? 'เหลือ 1 วัน'
                : 'เหลือ $days วัน';
        buffer.writeln('- ${item.emoji} ${item.name} ($daysText)');
      }
    }

    return '''คุณเป็น AI ช่วยวางแผนการซื้อของ
รายการอาหารในตู้เย็นตอนนี้:
$buffer
กรุณาแนะนำรายการที่ควรซื้อเพิ่ม (10-15 รายการ) โดยคำนึงถึง:
1. ของที่ใกล้หมดและควรซื้อเพิ่ม
2. ของที่ขาดเพื่อทำอาหารครบมื้อ
3. ของที่ดีต่อสุขภาพ

ตอบในรูปแบบ JSON เท่านั้น:
{"items": [{"name": "ชื่อสินค้าภาษาไทย", "reason": "เหตุผลสั้นๆ", "category": "หมวดหมู่", "emoji": "emoji"}]}''';
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
      _items = [];
    });

    try {
      final prompt = _buildPrompt();
      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _groqModel,
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('API error ${response.statusCode}: ${response.body}');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final content = decoded['choices'][0]['message']['content'] as String;

      // Extract JSON from the response (may have surrounding text)
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(content);
      if (jsonMatch == null) {
        throw Exception('ไม่พบข้อมูล JSON ในคำตอบ');
      }

      final parsed = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      final itemsList = parsed['items'] as List<dynamic>;
      final items = itemsList
          .map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'เกิดข้อผิดพลาด: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI ช่วยซื้อของ 🛒',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 2),
              Text(
                'รายการช็อปปิ้ง',
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ],
          ),
          _loading
              ? Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: _generate,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_items.isEmpty) {
      return const Center(
        child: Text(
          'กดปุ่มรีเฟรชเพื่อสร้างรายการ',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return _buildList();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'AI กำลังวิเคราะห์ตู้เย็น...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'รอสักครู่นะคะ',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.danger),
            const SizedBox(height: 16),
            const Text(
              'ไม่สามารถสร้างรายการได้',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('ลองใหม่'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final checked = _items.where((i) => i.checked).length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_items.length} รายการ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (checked > 0)
                      Text(
                        'เลือกแล้ว $checked รายการ',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.auto_awesome_outlined, size: 16),
                label: const Text('สร้างใหม่'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _ShoppingItemTile(
              item: _items[index],
              onToggle: () {
                setState(() {
                  _items[index].checked = !_items[index].checked;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;
  final VoidCallback onToggle;

  const _ShoppingItemTile({required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: item.checked
              ? AppColors.primary.withOpacity(0.08)
              : Theme.of(context).cardTheme.color ?? AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.checked ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: item.checked ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: item.checked ? AppColors.primary : AppColors.textSecondary.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: item.checked
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 18)
                  : null,
            ),
            const SizedBox(width: 14),
            Text(item.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      decoration:
                          item.checked ? TextDecoration.lineThrough : null,
                      color: item.checked
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (item.reason.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.reason,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.category,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

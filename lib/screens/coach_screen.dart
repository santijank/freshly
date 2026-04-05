import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/fridge_store.dart';
import '../models/meal_log.dart';
import '../models/meal_store.dart';
import '../services/coach_ai_service.dart';
import '../theme/app_theme.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _loading = false;

  static const _suggestions = [
    'วันนี้ควรกินอะไรเพิ่ม?',
    'วางแผนมื้ออาหารพรุ่งนี้',
    'วิเคราะห์การกินของฉัน',
    'แนะนำของในตู้เย็น',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _buildContext() {
    final store = MealStore.instance;
    final profile = store.profile;
    final todayMeals = store.todayMeals;
    final todayNutrition = store.todayNutrition;
    final fridgeItems = FridgeStore.instance.items;

    final weeklyData = store.weeklyNutrition;
    final weeklyText = weeklyData.entries.map((e) {
      final n = e.value;
      return '${e.key.day}/${e.key.month}: ${n.calories.round()} แคล';
    }).join(', ');

    return '''
--- ข้อมูลผู้ใช้ ---
ชื่อ: ${profile?.name ?? 'ไม่ระบุ'}
เป้าหมาย: ${profile?.goalLabel ?? 'ไม่ระบุ'}
เป้าแคลอรี่/วัน: ${profile?.dailyCalorieTarget ?? 2000}
เป้าโปรตีน: ${profile?.dailyProteinTarget ?? 120}g
BMI: ${profile?.bmi.toStringAsFixed(1) ?? 'ไม่ระบุ'} (${profile?.bmiLabel ?? ''})

--- วันนี้ ---
กินไปแล้ว: ${todayNutrition.calories.round()} แคล
โปรตีน: ${todayNutrition.protein.round()}g | คาร์บ: ${todayNutrition.carbs.round()}g | ไขมัน: ${todayNutrition.fat.round()}g
มื้ออาหาร: ${todayMeals.map((m) => '${m.mealType.label}(${m.items.map((i) => i.name).join(', ')})').join(' | ')}

--- 7 วันที่ผ่านมา ---
$weeklyText

--- ของในตู้เย็น ---
${fridgeItems.take(15).map((i) => i.name).join(', ')}
''';
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _loading) return;

    setState(() {
      _messages.add(_ChatMessage(text: trimmed, isUser: true));
      _loading = true;
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      final context = _buildContext();
      final reply = await CoachAiService().sendMessage(
        trimmed,
        context: context,
      );
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(text: reply, isUser: false));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            text: 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง 🙏',
            isUser: false,
          ));
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.background : AppColors.background;
    final cardColor = isDark ? AppColorsDark.cardBg : AppColors.cardBg;
    final textPrimary =
        isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(textPrimary, textSecondary),
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState(textPrimary, textSecondary, cardColor)
                  : _buildChatList(isDark),
            ),
            if (_loading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('🌿', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _LoadingDot(delay: 0),
                          const SizedBox(width: 4),
                          _LoadingDot(delay: 150),
                          const SizedBox(width: 4),
                          _LoadingDot(delay: 300),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            _buildInputBar(isDark, textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color textPrimary, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nourish Coach',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                Text(
                  'ที่ปรึกษาด้านโภชนาการ AI',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (_messages.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _messages.clear()),
              child: Text(
                'ล้าง',
                style: GoogleFonts.nunito(
                  color: textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      Color textPrimary, Color textSecondary, Color cardColor) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              const Text('🌿', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 12),
              Text(
                'สวัสดีครับ!',
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ถามอะไรเกี่ยวกับโภชนาการได้เลย',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'คำถามแนะนำ',
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ..._suggestions.map((s) => _SuggestionChip(
              text: s,
              onTap: () => _sendMessage(s),
            )),
      ],
    );
  }

  Widget _buildChatList(bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
        return _MessageBubble(
          message: msg,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildInputBar(bool isDark, Color textSecondary) {
    final surfaceColor = isDark ? AppColorsDark.surface : AppColors.surface;
    final bgColor = isDark ? AppColorsDark.cardBg : Colors.white;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              style: GoogleFonts.nunito(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'พิมพ์ข้อความ...',
                hintStyle: GoogleFonts.nunito(
                    color: textSecondary, fontSize: 14),
                filled: true,
                fillColor: surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
              onSubmitted: _loading ? null : _sendMessage,
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _loading
                ? null
                : () => _sendMessage(_inputController.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _loading
                    ? AppColors.accent
                    : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  _ChatMessage({
    required this.text,
    required this.isUser,
  }) : time = DateTime.now();
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final bool isDark;

  const _MessageBubble({
    required this.message,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final cardColor =
        isDark ? AppColorsDark.cardBg : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🌿', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                message.text,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: isUser
                      ? Colors.white
                      : (isDark
                          ? AppColorsDark.textPrimary
                          : AppColors.textPrimary),
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('👤', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SuggestionChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Text(
              text,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingDot extends StatefulWidget {
  final int delay;

  const _LoadingDot({required this.delay});

  @override
  State<_LoadingDot> createState() => _LoadingDotState();
}

class _LoadingDotState extends State<_LoadingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, -4 * _animation.value),
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.6 + 0.4 * _animation.value),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

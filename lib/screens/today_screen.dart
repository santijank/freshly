import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_metrics.dart';
import '../models/health_store.dart';
import '../models/meal_log.dart';
import '../models/meal_store.dart';
import '../services/coach_ai_service.dart';
import '../theme/app_theme.dart';
import 'health_screen.dart';
import 'profile_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  String? _aiTip;
  bool _loadingTip = false;

  @override
  void initState() {
    super.initState();
    _loadAiTip();
  }

  Future<void> _loadAiTip() async {
    // Cache by date
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final cacheKey = 'nourish_tip_${today.year}_${today.month}_${today.day}';
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      if (mounted) setState(() => _aiTip = cached);
      return;
    }

    setState(() => _loadingTip = true);
    try {
      final store = MealStore.instance;
      final profile = store.profile;
      final nutrition = store.todayNutrition;

      final context = profile == null
          ? 'ผู้ใช้ยังไม่ได้ตั้งค่าโปรไฟล์'
          : '''
ชื่อ: ${profile.name}
เป้าหมาย: ${profile.goalLabel}
เป้าแคลอรี่วันนี้: ${profile.dailyCalorieTarget} แคล
กินไปแล้ว: ${nutrition.calories.round()} แคล
โปรตีน: ${nutrition.protein.round()}/${profile.dailyProteinTarget}g
คาร์บ: ${nutrition.carbs.round()}/${profile.dailyCarbTarget}g
ไขมัน: ${nutrition.fat.round()}/${profile.dailyFatTarget}g
''';

      final tip = await CoachAiService().generateDailyTip(context: context);
      await prefs.setString(cacheKey, tip);
      if (mounted) setState(() => _aiTip = tip);
    } catch (_) {
      if (mounted) setState(() => _aiTip = 'ดื่มน้ำให้เพียงพอ 8 แก้วต่อวัน และทานอาหารครบ 5 หมู่นะครับ! 💧');
    } finally {
      if (mounted) setState(() => _loadingTip = false);
    }
  }

  Future<void> _deleteMeal(String id) async {
    await MealStore.instance.deleteMeal(id);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MealStore.instance,
      builder: (context, _) {
        final store = MealStore.instance;
        final profile = store.profile;
        final nutrition = store.todayNutrition;
        final meals = store.todayMeals;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final calorieTarget = profile?.dailyCalorieTarget ?? 2000;
        final proteinTarget = profile?.dailyProteinTarget ?? 120;
        final carbTarget = profile?.dailyCarbTarget ?? 250;
        final fatTarget = profile?.dailyFatTarget ?? 65;

        final bgColor = isDark ? AppColorsDark.background : AppColors.background;
        final cardColor = isDark ? AppColorsDark.cardBg : AppColors.cardBg;
        final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
        final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _buildHeader(profile?.name, textPrimary, textSecondary),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _CalorieRingCard(
                      consumed: nutrition.calories,
                      target: calorieTarget.toDouble(),
                      cardColor: cardColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _MacroRow(
                      protein: nutrition.protein,
                      proteinTarget: proteinTarget.toDouble(),
                      carbs: nutrition.carbs,
                      carbTarget: carbTarget.toDouble(),
                      fat: nutrition.fat,
                      fatTarget: fatTarget.toDouble(),
                      cardColor: cardColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _AiTipCard(
                      tip: _aiTip,
                      loading: _loadingTip,
                      cardColor: cardColor,
                      textPrimary: textPrimary,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Row(
                      children: [
                        Text(
                          'มื้ออาหารวันนี้',
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (meals.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${meals.length}',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (meals.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _EmptyMealsCard(
                          cardColor: cardColor, textSecondary: textSecondary),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final meal = meals[i];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: _MealCard(
                            meal: meal,
                            cardColor: cardColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            onDelete: () => _deleteMeal(meal.id),
                          ),
                        );
                      },
                      childCount: meals.length,
                    ),
                  ),
                // ── Health card ──
                SliverToBoxAdapter(
                  child: ListenableBuilder(
                    listenable: HealthStore.instance,
                    builder: (ctx, _) {
                      final latest = HealthStore.instance.latestReport;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: latest != null
                            ? _HealthSummaryCard(
                                report: latest,
                                cardColor: cardColor,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              )
                            : _AddHealthCard(
                                cardColor: cardColor,
                                textSecondary: textSecondary,
                              ),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: _HealthStatsRow(
                      profile: profile,
                      streak: store.streakDays,
                      cardColor: cardColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
      String? name, Color textPrimary, Color textSecondary) {
    final now = DateTime.now();
    final thaiMonths = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    final dateStr =
        '${now.day} ${thaiMonths[now.month - 1]} ${now.year + 543}';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'สวัสดี ${name ?? 'คุณ'}! 🌿',
                style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              Text(
                dateStr,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Calorie Ring ────────────────────────────────────────────────────

class _CalorieRingCard extends StatelessWidget {
  final double consumed;
  final double target;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;

  const _CalorieRingCard({
    required this.consumed,
    required this.target,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (consumed / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(160, 160),
                  painter: _RingPainter(
                    progress: progress,
                    trackColor: AppColors.accent.withOpacity(0.3),
                    progressColor: consumed > target
                        ? AppColors.warning
                        : AppColors.primary,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      consumed.round().toString(),
                      style: GoogleFonts.nunito(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'แคลอรี่',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${consumed.round()} / ${target.round()} แคลอรี่',
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            consumed >= target
                ? 'ถึงเป้าหมายแล้ว! 🎉'
                : 'เหลืออีก ${(target - consumed).round()} แคล',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: consumed >= target ? AppColors.primary : textSecondary,
              fontWeight: consumed >= target ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 12;
    const strokeWidth = 14.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Track
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ── Macro Row ──────────────────────────────────────────────────────

class _MacroRow extends StatelessWidget {
  final double protein;
  final double proteinTarget;
  final double carbs;
  final double carbTarget;
  final double fat;
  final double fatTarget;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;

  const _MacroRow({
    required this.protein,
    required this.proteinTarget,
    required this.carbs,
    required this.carbTarget,
    required this.fat,
    required this.fatTarget,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MacroCard(
            emoji: '💪',
            label: 'โปรตีน',
            current: protein,
            target: proteinTarget,
            color: const Color(0xFF1565C0),
            cardColor: cardColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MacroCard(
            emoji: '🌾',
            label: 'คาร์บ',
            current: carbs,
            target: carbTarget,
            color: const Color(0xFFE65100),
            cardColor: cardColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MacroCard(
            emoji: '🥑',
            label: 'ไขมัน',
            current: fat,
            target: fatTarget,
            color: const Color(0xFF2E7D32),
            cardColor: cardColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String emoji;
  final String label;
  final double current;
  final double target;
  final Color color;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;

  const _MacroCard({
    required this.emoji,
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (current / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${current.round()}/${target.round()}g',
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── AI Tip ─────────────────────────────────────────────────────────

class _AiTipCard extends StatelessWidget {
  final String? tip;
  final bool loading;
  final Color cardColor;
  final Color textPrimary;

  const _AiTipCard({
    required this.tip,
    required this.loading,
    required this.cardColor,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('🤖', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: loading
                ? const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Coach',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tip ?? 'กำลังวิเคราะห์...',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Meal Card ──────────────────────────────────────────────────────

class _MealCard extends StatelessWidget {
  final MealLog meal;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onDelete;

  const _MealCard({
    required this.meal,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final time =
        '${meal.date.hour.toString().padLeft(2, '0')}:${meal.date.minute.toString().padLeft(2, '0')}';
    final summary = meal.items.map((i) => i.name).join(', ');
    final totalCal = meal.totalNutrition.calories.round();

    return Dismissible(
      key: Key(meal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Text(
              meal.mealType.emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        meal.mealType.label,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        time,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$totalCal แคล',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────

class _EmptyMealsCard extends StatelessWidget {
  final Color cardColor;
  final Color textSecondary;

  const _EmptyMealsCard({
    required this.cardColor,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          const Text('🍽️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'ยังไม่มีบันทึกวันนี้',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'กดปุ่ม + เพื่อบันทึกมื้ออาหาร',
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Health Stats ───────────────────────────────────────────────────

class _HealthStatsRow extends StatelessWidget {
  final dynamic profile;
  final int streak;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;

  const _HealthStatsRow({
    required this.profile,
    required this.streak,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final bmi = profile?.bmi;
    final bmiLabel = profile?.bmiLabel;

    return Row(
      children: [
        if (bmi != null) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('⚖️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BMI ${bmi.toStringAsFixed(1)}',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        bmiLabel ?? '',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$streak วัน',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Streak',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Health Summary Card (for Today screen) ─────────────────────────

class _HealthSummaryCard extends StatelessWidget {
  final LabReport report;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;

  const _HealthSummaryCard({
    required this.report,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    // Priority metrics to show: FBS, Cholesterol, LDL, HbA1c
    const priority = [
      'fasting blood sugar',
      'fbs',
      'total cholesterol',
      'cholesterol',
      'ldl',
      'hba1c',
    ];

    final keyMetrics = <HealthMetric>[];
    for (final p in priority) {
      final match = report.metrics.where(
        (m) => m.name.toLowerCase().contains(p),
      );
      if (match.isNotEmpty) keyMetrics.add(match.first);
      if (keyMetrics.length >= 4) break;
    }
    // Fallback: show first 4 if priority finds nothing
    if (keyMetrics.isEmpty) {
      keyMetrics.addAll(report.metrics.take(4));
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HealthScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('❤️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ผลตรวจร่างกาย',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
                Text(
                  'ดูทั้งหมด →',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (report.hasAbnormal) ...[
              const SizedBox(height: 4),
              Text(
                '⚠️ มีค่าผิดปกติ ${report.abnormalMetrics.length} ค่า',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: keyMetrics
                    .map((m) => _MetricChip(metric: m))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final HealthMetric metric;
  const _MetricChip({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: metric.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: metric.statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.nameThai,
            style: GoogleFonts.nunito(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                metric.value.toStringAsFixed(1),
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: metric.statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddHealthCard extends StatelessWidget {
  final Color cardColor;
  final Color textSecondary;

  const _AddHealthCard({
    required this.cardColor,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HealthScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const Text('🩺', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'เพิ่มผลตรวจเลือด',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'สแกนเพื่อรับแผนอาหารเฉพาะตัวจาก AI',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/meal_log.dart';
import '../models/meal_store.dart';
import '../services/coach_ai_service.dart';
import '../theme/app_theme.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  String? _weeklyInsight;
  bool _loadingInsight = false;

  @override
  void initState() {
    super.initState();
    _loadInsight();
  }

  Future<void> _loadInsight() async {
    setState(() => _loadingInsight = true);
    try {
      final store = MealStore.instance;
      final profile = store.profile;
      final weekly = store.weeklyNutrition;

      final weeklyText = weekly.entries.map((e) {
        final day = e.key;
        final n = e.value;
        return '${day.day}/${day.month}: ${n.calories.round()} แคล, โปรตีน ${n.protein.round()}g';
      }).join('\n');

      final context = '''
โปรไฟล์: ${profile?.name ?? 'ไม่ระบุ'}
เป้าแคลอรี่: ${profile?.dailyCalorieTarget ?? 2000}/วัน
ข้อมูล 7 วันที่ผ่านมา:
$weeklyText
''';

      final insight =
          await CoachAiService().generateWeeklyInsight(context: context);
      if (mounted) setState(() => _weeklyInsight = insight);
    } catch (_) {
      if (mounted) {
        setState(() =>
            _weeklyInsight = 'ติดตามอาหารสม่ำเสมอเพื่อรับข้อมูลเชิงลึก');
      }
    } finally {
      if (mounted) setState(() => _loadingInsight = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MealStore.instance,
      builder: (context, _) {
        final store = MealStore.instance;
        final profile = store.profile;
        final weeklyData = store.weeklyNutrition;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final bgColor =
            isDark ? AppColorsDark.background : AppColors.background;
        final textPrimary =
            isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
        final textSecondary =
            isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
        final cardColor =
            isDark ? AppColorsDark.cardBg : AppColors.cardBg;

        final calorieTarget =
            (profile?.dailyCalorieTarget ?? 2000).toDouble();

        // Health score calculation
        final entries = weeklyData.entries.toList();
        int daysMetCalorie = entries
            .where((e) =>
                e.value.calories >= calorieTarget * 0.8 &&
                e.value.calories <= calorieTarget * 1.2)
            .length;
        int daysWithData =
            entries.where((e) => e.value.calories > 0).length;

        double avgProteinPct = daysWithData > 0
            ? entries
                    .where((e) => e.value.calories > 0)
                    .map((e) =>
                        (e.value.protein /
                            (profile?.dailyProteinTarget ?? 120)))
                    .fold(0.0, (a, b) => a + b) /
                daysWithData
            : 0;

        int consistencyBonus = daysWithData;

        int healthScore = ((daysMetCalorie / 7) * 40 +
                (avgProteinPct.clamp(0, 1)) * 30 +
                (consistencyBonus / 7) * 30)
            .round();

        // Top foods
        final foodCount = <String, int>{};
        for (final meal in store.allMeals) {
          final now = DateTime.now();
          final weekAgo = now.subtract(const Duration(days: 7));
          if (meal.date.isAfter(weekAgo)) {
            for (final item in meal.items) {
              foodCount[item.name] = (foodCount[item.name] ?? 0) + 1;
            }
          }
        }
        final topFoods = foodCount.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top5 = topFoods.take(5).toList();

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Text(
                      'สถิติสุขภาพ 📊',
                      style: GoogleFonts.nunito(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ),
                // Week label
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: Text(
                      '7 วันที่ผ่านมา',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ),
                // Calorie chart
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _CalorieBarChart(
                      weeklyData: weeklyData,
                      calorieTarget: calorieTarget,
                      cardColor: cardColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                ),
                // Health Score
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _HealthScoreCard(
                      score: healthScore,
                      cardColor: cardColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                ),
                // Macro breakdown
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _MacroBreakdown(
                      weeklyData: weeklyData,
                      cardColor: cardColor,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ),
                ),
                // Top foods
                if (top5.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: _TopFoodsCard(
                        foods: top5,
                        cardColor: cardColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ),
                  ),
                // AI insight
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: _WeeklyInsightCard(
                      insight: _weeklyInsight,
                      loading: _loadingInsight,
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
}

// ── Bar Chart ──────────────────────────────────────────────────────

class _CalorieBarChart extends StatelessWidget {
  final Map<DateTime, FoodNutrition> weeklyData;
  final double calorieTarget;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;

  const _CalorieBarChart({
    required this.weeklyData,
    required this.calorieTarget,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final entries = weeklyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final maxVal = [
      calorieTarget * 1.5,
      ...entries.map((e) => e.value.calories),
    ].reduce((a, b) => a > b ? a : b);

    final thaiDays = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'แคลอรี่รายวัน',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: CustomPaint(
              size: const Size(double.infinity, 140),
              painter: _BarChartPainter(
                entries: entries,
                maxVal: maxVal,
                targetVal: calorieTarget,
                textSecondary: textSecondary,
                thaiDays: thaiDays,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendDot(
                  color: AppColors.primary, label: 'ต่ำกว่าเป้า/พอดี'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.warning, label: 'เกินเป้า'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<MapEntry<DateTime, FoodNutrition>> entries;
  final double maxVal;
  final double targetVal;
  final Color textSecondary;
  final List<String> thaiDays;

  _BarChartPainter({
    required this.entries,
    required this.maxVal,
    required this.targetVal,
    required this.textSecondary,
    required this.thaiDays,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    const labelHeight = 20.0;
    final chartHeight = size.height - labelHeight;
    final barWidth = size.width / entries.length;
    const barPadding = 6.0;

    // Target line
    final targetY =
        chartHeight - (targetVal / maxVal).clamp(0, 1) * chartHeight;
    final targetPaint = Paint()
      ..color = AppColors.warning.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final dashPath = Path();
    double x = 0;
    while (x < size.width) {
      dashPath.moveTo(x, targetY);
      dashPath.lineTo(x + 6, targetY);
      x += 10;
    }
    canvas.drawPath(dashPath, targetPaint);

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final calories = entry.value.calories;
      final normalized = maxVal > 0 ? (calories / maxVal).clamp(0.0, 1.0) : 0.0;
      final barHeight = normalized * chartHeight;

      final left = i * barWidth + barPadding;
      final right = (i + 1) * barWidth - barPadding;
      final top = chartHeight - barHeight;

      final color =
          calories > targetVal ? AppColors.warning : AppColors.primary;
      final barPaint = Paint()
        ..color = calories == 0 ? color.withOpacity(0.2) : color
        ..style = PaintingStyle.fill;

      final rrect = RRect.fromLTRBR(
          left, top, right, chartHeight, const Radius.circular(4));
      canvas.drawRRect(rrect, barPaint);

      // Day label
      final dayIndex = entry.key.weekday - 1; // Monday=0
      final dayLabel =
          dayIndex < thaiDays.length ? thaiDays[dayIndex] : '?';
      final tp = TextPainter(
        text: TextSpan(
          text: dayLabel,
          style: TextStyle(
            fontSize: 11,
            color: textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          left + (right - left) / 2 - tp.width / 2,
          chartHeight + 4,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_BarChartPainter old) => true;
}

// ── Health Score ───────────────────────────────────────────────────

class _HealthScoreCard extends StatelessWidget {
  final int score;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;

  const _HealthScoreCard({
    required this.score,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  Color get _scoreColor {
    if (score >= 70) return AppColors.primary;
    if (score >= 40) return AppColors.warning;
    return AppColors.danger;
  }

  String get _scoreLabel {
    if (score >= 70) return 'ยอดเยี่ยม! 🌟';
    if (score >= 40) return 'พอใช้ได้ 👍';
    return 'ต้องปรับปรุง 💪';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: _ScoreRingPainter(
                score: score / 100,
                color: _scoreColor,
              ),
              child: Center(
                child: Text(
                  '$score',
                  style: GoogleFonts.nunito(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _scoreColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'คะแนนสุขภาพสัปดาห์นี้',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                ),
                Text(
                  _scoreLabel,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _scoreColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'จาก 100 คะแนน',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: textSecondary,
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

class _ScoreRingPainter extends CustomPainter {
  final double score;
  final Color color;

  _ScoreRingPainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    final trackPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * score,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) => old.score != score;
}

// ── Macro Breakdown ────────────────────────────────────────────────

class _MacroBreakdown extends StatelessWidget {
  final Map<DateTime, FoodNutrition> weeklyData;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;

  const _MacroBreakdown({
    required this.weeklyData,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final nonEmpty =
        weeklyData.values.where((n) => n.calories > 0).toList();
    if (nonEmpty.isEmpty) {
      return const SizedBox.shrink();
    }

    final avgProtein =
        nonEmpty.map((n) => n.protein).fold(0.0, (a, b) => a + b) /
            nonEmpty.length;
    final avgCarbs =
        nonEmpty.map((n) => n.carbs).fold(0.0, (a, b) => a + b) /
            nonEmpty.length;
    final avgFat = nonEmpty.map((n) => n.fat).fold(0.0, (a, b) => a + b) /
        nonEmpty.length;

    final totalMacroCalories =
        avgProtein * 4 + avgCarbs * 4 + avgFat * 9;
    final proteinPct =
        totalMacroCalories > 0 ? avgProtein * 4 / totalMacroCalories : 0.0;
    final carbPct =
        totalMacroCalories > 0 ? avgCarbs * 4 / totalMacroCalories : 0.0;
    final fatPct =
        totalMacroCalories > 0 ? avgFat * 9 / totalMacroCalories : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'สัดส่วนสารอาหาร (เฉลี่ย)',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 16,
              child: Row(
                children: [
                  _MacroBar(
                      flex: (proteinPct * 100).round(),
                      color: const Color(0xFF1565C0)),
                  _MacroBar(
                      flex: (carbPct * 100).round(),
                      color: const Color(0xFFE65100)),
                  _MacroBar(
                      flex: (fatPct * 100).round(),
                      color: const Color(0xFF2E7D32)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MacroLegend(
                label: '💪 โปรตีน',
                pct: proteinPct,
                grams: avgProtein,
                color: const Color(0xFF1565C0),
                textSecondary: textSecondary,
              ),
              _MacroLegend(
                label: '🌾 คาร์บ',
                pct: carbPct,
                grams: avgCarbs,
                color: const Color(0xFFE65100),
                textSecondary: textSecondary,
              ),
              _MacroLegend(
                label: '🥑 ไขมัน',
                pct: fatPct,
                grams: avgFat,
                color: const Color(0xFF2E7D32),
                textSecondary: textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final int flex;
  final Color color;

  const _MacroBar({required this.flex, required this.color});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: flex > 0 ? flex : 1,
      child: Container(color: color),
    );
  }
}

class _MacroLegend extends StatelessWidget {
  final String label;
  final double pct;
  final double grams;
  final Color color;
  final Color textSecondary;

  const _MacroLegend({
    required this.label,
    required this.pct,
    required this.grams,
    required this.color,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.nunito(fontSize: 11, color: textSecondary),
        ),
        Text(
          '${(pct * 100).round()}%',
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          '${grams.round()}g/วัน',
          style: GoogleFonts.nunito(fontSize: 11, color: textSecondary),
        ),
      ],
    );
  }
}

// ── Top Foods ──────────────────────────────────────────────────────

class _TopFoodsCard extends StatelessWidget {
  final List<MapEntry<String, int>> foods;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;

  const _TopFoodsCard({
    required this.foods,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'อาหารที่ทานบ่อยสัปดาห์นี้',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...foods.asMap().entries.map((e) {
            final rank = e.key + 1;
            final food = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: rank == 1
                          ? const Color(0xFFFFD700)
                          : rank == 2
                              ? const Color(0xFFC0C0C0)
                              : rank == 3
                                  ? const Color(0xFFCD7F32)
                                  : AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: rank <= 3
                              ? Colors.white
                              : textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      food.key,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${food.value} ครั้ง',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Weekly Insight ─────────────────────────────────────────────────

class _WeeklyInsightCard extends StatelessWidget {
  final String? insight;
  final bool loading;

  const _WeeklyInsightCard({required this.insight, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'AI วิเคราะห์สัปดาห์นี้',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          loading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                )
              : Text(
                  insight ?? 'กำลังวิเคราะห์...',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
        ],
      ),
    );
  }
}

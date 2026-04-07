import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/meal_store.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late int _age;
  late double _weightKg;
  late double _heightCm;
  late String _gender;
  late HealthGoal _goal;
  late String _name;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = MealStore.instance.profile;
    _name = p?.name ?? '';
    _age = p?.age ?? 25;
    _weightKg = p?.weightKg ?? 65.0;
    _heightCm = p?.heightCm ?? 170.0;
    _gender = p?.gender ?? 'male';
    _goal = p?.goal ?? HealthGoal.eatHealthier;
  }

  UserProfile get _preview => UserProfile.create(
        name: _name,
        age: _age,
        weightKg: _weightKg,
        heightCm: _heightCm,
        gender: _gender,
        goal: _goal,
      );

  double get _bmi => _weightKg / ((_heightCm / 100) * (_heightCm / 100));

  String get _bmiLabel {
    final b = _bmi;
    if (b < 18.5) return 'น้ำหนักน้อย';
    if (b < 25) return 'ปกติ';
    if (b < 30) return 'น้ำหนักเกิน';
    return 'อ้วน';
  }

  Color get _bmiColor {
    final b = _bmi;
    if (b < 18.5) return Colors.blue;
    if (b < 25) return AppColors.primary;
    if (b < 30) return Colors.orange;
    return Colors.red;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final profile = _preview;
    await MealStore.instance.saveProfile(profile);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'บันทึกข้อมูลแล้ว',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.background : AppColors.background;
    final cardColor = isDark ? AppColorsDark.cardBg : AppColors.cardBg;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    final preview = _preview;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'โปรไฟล์ & เป้าหมาย',
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Calorie summary card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'เป้าหมายแคลอรี่ของคุณ',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${preview.dailyCalorieTarget}',
                          style: GoogleFonts.nunito(
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'แคลอรี่/วัน',
                          style: GoogleFonts.nunito(
                              fontSize: 13, color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _MacroChip(
                                label: 'โปรตีน',
                                value: '${preview.dailyProteinTarget}g',
                                emoji: '💪'),
                            _MacroChip(
                                label: 'คาร์บ',
                                value: '${preview.dailyCarbTarget}g',
                                emoji: '🌾'),
                            _MacroChip(
                                label: 'ไขมัน',
                                value: '${preview.dailyFatTarget}g',
                                emoji: '🥑'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // BMI card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _bmiColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _bmi.toStringAsFixed(1),
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: _bmiColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ดัชนีมวลกาย (BMI)',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: textSecondary,
                              ),
                            ),
                            Text(
                              _bmiLabel,
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _bmiColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Gender
                  _SectionLabel(label: 'เพศ', textSecondary: textSecondary),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _GenderChip(
                        label: '👨 ชาย',
                        selected: _gender == 'male',
                        onTap: () => setState(() => _gender = 'male'),
                      ),
                      const SizedBox(width: 12),
                      _GenderChip(
                        label: '👩 หญิง',
                        selected: _gender == 'female',
                        onTap: () => setState(() => _gender = 'female'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Age
                  _SliderField(
                    label: 'อายุ',
                    value: _age.toDouble(),
                    min: 10,
                    max: 90,
                    divisions: 80,
                    displayValue: '$_age ปี',
                    onChanged: (v) => setState(() => _age = v.round()),
                    cardColor: cardColor,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 20),

                  // Weight
                  _SliderField(
                    label: 'น้ำหนัก',
                    value: _weightKg,
                    min: 40,
                    max: 150,
                    divisions: 110,
                    displayValue: '${_weightKg.toStringAsFixed(1)} กก.',
                    onChanged: (v) =>
                        setState(() => _weightKg = (v * 10).round() / 10),
                    cardColor: cardColor,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 20),

                  // Height
                  _SliderField(
                    label: 'ส่วนสูง',
                    value: _heightCm,
                    min: 140,
                    max: 220,
                    divisions: 80,
                    displayValue: '${_heightCm.toStringAsFixed(0)} ซม.',
                    onChanged: (v) =>
                        setState(() => _heightCm = v.roundToDouble()),
                    cardColor: cardColor,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 24),

                  // Goal
                  _SectionLabel(label: 'เป้าหมาย', textSecondary: textSecondary),
                  const SizedBox(height: 12),
                  ...HealthGoal.values.map((g) => _GoalTile(
                        goal: g,
                        selected: _goal == g,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        cardColor: cardColor,
                        onTap: () => setState(() => _goal = g),
                      )),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Save button
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'บันทึก',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color textSecondary;
  const _SectionLabel({required this.label, required this.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textSecondary,
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  const _MacroChip(
      {required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$emoji $value',
            style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        Text(label,
            style:
                GoogleFonts.nunito(fontSize: 11, color: Colors.white70)),
      ],
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _GenderChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SliderField extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final ValueChanged<double> onChanged;
  final Color cardColor;
  final Color textSecondary;

  const _SliderField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.onChanged,
    required this.cardColor,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  displayValue,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withOpacity(0.15),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  final HealthGoal goal;
  final bool selected;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardColor;
  final VoidCallback onTap;

  const _GoalTile({
    required this.goal,
    required this.selected,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardColor,
    required this.onTap,
  });

  static const _emojis = {
    HealthGoal.loseWeight: '⚖️',
    HealthGoal.gainMuscle: '💪',
    HealthGoal.maintain: '🎯',
    HealthGoal.eatHealthier: '🥗',
  };
  static const _labels = {
    HealthGoal.loseWeight: 'ลดน้ำหนัก',
    HealthGoal.gainMuscle: 'เพิ่มกล้ามเนื้อ',
    HealthGoal.maintain: 'รักษาน้ำหนัก',
    HealthGoal.eatHealthier: 'กินดีขึ้น',
  };
  static const _descs = {
    HealthGoal.loseWeight: 'ลดแคลอรี่ 500 ต่อวัน',
    HealthGoal.gainMuscle: 'เพิ่มแคลอรี่และโปรตีน',
    HealthGoal.maintain: 'รักษาน้ำหนักปัจจุบัน',
    HealthGoal.eatHealthier: 'โภชนาการสมดุล',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(_emojis[goal]!,
                style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _labels[goal]!,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    _descs[goal]!,
                    style: GoogleFonts.nunito(
                        fontSize: 12, color: textSecondary),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}

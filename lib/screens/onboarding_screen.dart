import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/meal_store.dart';
import '../models/user_profile.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1
  final _nameController = TextEditingController();

  // Step 2
  int _age = 25;
  double _weightKg = 65.0;
  double _heightCm = 170.0;
  String _gender = 'male';

  // Step 3
  HealthGoal _goal = HealthGoal.eatHealthier;

  bool _saving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty) {
        _showError('กรุณาใส่ชื่อของคุณ');
        return;
      }
    }
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final profile = UserProfile.create(
      name: _nameController.text.trim(),
      age: _age,
      weightKg: _weightKg,
      heightCm: _heightCm,
      gender: _gender,
      goal: _goal,
    );
    await MealStore.instance.saveProfile(profile);
    if (!mounted) return;
    // Navigate to main app
    Navigator.of(context).pushReplacementNamed('/main');
  }

  UserProfile get _previewProfile => UserProfile.create(
        name: _nameController.text.trim().isEmpty
            ? 'คุณ'
            : _nameController.text.trim(),
        age: _age,
        weightKg: _weightKg,
        heightCm: _heightCm,
        gender: _gender,
        goal: _goal,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
              ],
            ),
          ),
          _buildNavButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final titles = [
      'สวัสดีครับ!',
      'ข้อมูลร่างกาย',
      'เป้าหมายของคุณ',
    ];
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nourish 🌿',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  titles[_currentStep],
                  key: ValueKey(_currentStep),
                  style: GoogleFonts.nunito(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      color: AppColors.primary,
      child: Row(
        children: List.generate(3, (i) {
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              color: i <= _currentStep
                  ? Colors.white
                  : Colors.white.withOpacity(0.3),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'ผมชื่อ Nourish 🌿',
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ผมจะช่วยติดตามโภชนาการและดูแลสุขภาพของคุณ\nขอรู้จักคุณหน่อยได้ไหมครับ?',
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'ชื่อของคุณ',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'เช่น สมชาย',
              hintStyle: GoogleFonts.nunito(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('🌿', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Nourish จะวิเคราะห์อาหารด้วย AI, ติดตามแคลอรี่, และให้คำแนะนำส่วนตัว',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Gender
          Text(
            'เพศ',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
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
          const SizedBox(height: 24),
          // Age
          _SliderField(
            label: 'อายุ',
            value: _age.toDouble(),
            min: 10,
            max: 90,
            divisions: 80,
            displayValue: '$_age ปี',
            onChanged: (v) => setState(() => _age = v.round()),
          ),
          const SizedBox(height: 24),
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
          ),
          const SizedBox(height: 24),
          // Height
          _SliderField(
            label: 'ส่วนสูง',
            value: _heightCm,
            min: 140,
            max: 220,
            divisions: 80,
            displayValue: '${_heightCm.toStringAsFixed(0)} ซม.',
            onChanged: (v) => setState(() => _heightCm = v.roundToDouble()),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    final preview = _previewProfile;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'คุณต้องการอะไร?',
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ...HealthGoal.values.map((g) => _GoalCard(
                goal: g,
                selected: _goal == g,
                onTap: () => setState(() => _goal = g),
              )),
          const SizedBox(height: 24),
          // Calorie preview
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
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${preview.dailyCalorieTarget}',
                  style: GoogleFonts.nunito(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'แคลอรี่/วัน',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MacroPreview(
                        label: '💪 โปรตีน',
                        value: '${preview.dailyProteinTarget}g'),
                    _MacroPreview(
                        label: '🌾 คาร์บ',
                        value: '${preview.dailyCarbTarget}g'),
                    _MacroPreview(
                        label: '🥑 ไขมัน',
                        value: '${preview.dailyFatTarget}g'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButtons() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _prevStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                  child: Text(
                    'ย้อนกลับ',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _saving
                    ? null
                    : (_currentStep < 2 ? _nextStep : _finish),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _currentStep < 2 ? 'ถัดไป' : 'เริ่มเลย! 🚀',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color:
                selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : Colors.transparent,
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

  const _SliderField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
                color: AppColors.textSecondary,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
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
            inactiveTrackColor: AppColors.accent,
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
    );
  }
}

class _GoalCard extends StatelessWidget {
  final HealthGoal goal;
  final bool selected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.goal,
    required this.selected,
    required this.onTap,
  });

  static const _goalEmojis = {
    HealthGoal.loseWeight: '⚖️',
    HealthGoal.gainMuscle: '💪',
    HealthGoal.maintain: '🎯',
    HealthGoal.eatHealthier: '🥗',
  };

  static const _goalDescriptions = {
    HealthGoal.loseWeight: 'ลดแคลอรี่ 500 ต่อวัน เพื่อลดน้ำหนักอย่างปลอดภัย',
    HealthGoal.gainMuscle: 'เพิ่มแคลอรี่และโปรตีน เพื่อสร้างกล้ามเนื้อ',
    HealthGoal.maintain: 'รักษาน้ำหนักปัจจุบัน ด้วยอาหารสมดุล',
    HealthGoal.eatHealthier: 'กินอาหารที่มีคุณค่าทางโภชนาการมากขึ้น',
  };

  static const _goalLabels = {
    HealthGoal.loseWeight: 'ลดน้ำหนัก',
    HealthGoal.gainMuscle: 'เพิ่มกล้ามเนื้อ',
    HealthGoal.maintain: 'รักษาน้ำหนัก',
    HealthGoal.eatHealthier: 'กินดีขึ้น',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Text(
              _goalEmojis[goal]!,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _goalLabels[goal]!,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _goalDescriptions[goal]!,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

class _MacroPreview extends StatelessWidget {
  final String label;
  final String value;

  const _MacroPreview({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

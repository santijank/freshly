import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/fridge_store.dart';
import '../models/meal_log.dart';
import '../models/meal_store.dart';
import '../services/nutrition_ai_service.dart';
import '../theme/app_theme.dart';

Future<void> showLogMealSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _LogMealSheet(),
  );
}

class _LogMealSheet extends StatelessWidget {
  const _LogMealSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.cardBg : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'บันทึกมื้ออาหาร',
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColorsDark.textPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'เลือกวิธีบันทึก',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: isDark
                      ? AppColorsDark.textSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              _MethodCard(
                emoji: '📸',
                title: 'ถ่ายรูปอาหาร',
                subtitle: 'AI วิเคราะห์อาหารจากรูป',
                color: const Color(0xFF1565C0),
                onTap: () => _openCamera(context),
              ),
              const SizedBox(height: 12),
              _MethodCard(
                emoji: '✍️',
                title: 'พิมพ์บอก',
                subtitle: 'บอกว่ากินอะไร AI ประเมินให้',
                color: const Color(0xFF6A1B9A),
                onTap: () => _openTextInput(context),
              ),
              const SizedBox(height: 12),
              _MethodCard(
                emoji: '🧊',
                title: 'เลือกจากตู้เย็น',
                subtitle: 'เลือกวัตถุดิบที่มีในตู้เย็น',
                color: const Color(0xFF00695C),
                onTap: () => _openFridgePicker(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCamera(BuildContext context) async {
    Navigator.of(context).pop();
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      if (context.mounted) {
        _showError(context, 'ไม่พบกล้อง');
      }
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CameraCapturePage(camera: cameras.first),
      ),
    );
  }

  Future<void> _openTextInput(BuildContext context) async {
    Navigator.of(context).pop();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _TextInputSheet(),
    );
  }

  Future<void> _openFridgePicker(BuildContext context) async {
    Navigator.of(context).pop();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FridgePickerSheet(),
    );
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ── Method Card ────────────────────────────────────────────────────

class _MethodCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MethodCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: color,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Camera Page ────────────────────────────────────────────────────

class _CameraCapturePage extends StatefulWidget {
  final CameraDescription camera;

  const _CameraCapturePage({required this.camera});

  @override
  State<_CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<_CameraCapturePage> {
  late CameraController _controller;
  bool _initialized = false;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller.initialize().then((_) {
      if (mounted) setState(() => _initialized = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_capturing || !_initialized) return;
    setState(() => _capturing = true);
    try {
      final xfile = await _controller.takePicture();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              _AnalyzingPage(imageFile: File(xfile.path), method: 'image'),
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ถ่ายรูปอาหาร',
          style: GoogleFonts.nunito(color: Colors.white),
        ),
      ),
      body: _initialized
          ? Stack(
              children: [
                Positioned.fill(child: CameraPreview(_controller)),
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _capture,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _capturing
                              ? Colors.grey
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 4),
                        ),
                        child: _capturing
                            ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.grey,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}

// ── Text Input Sheet ───────────────────────────────────────────────

class _TextInputSheet extends StatefulWidget {
  const _TextInputSheet();

  @override
  State<_TextInputSheet> createState() => _TextInputSheetState();
}

class _TextInputSheetState extends State<_TextInputSheet> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _loading = true);
    try {
      Navigator.of(context).pop();
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AnalyzingSheet(text: text),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.cardBg : Colors.white;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'กินอะไรมาบ้าง?',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColorsDark.textPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 3,
              style: GoogleFonts.nunito(fontSize: 15),
              decoration: InputDecoration(
                hintText:
                    'เช่น ข้าวผัดหมู 1 จาน, ไข่เจียว 2 ฟอง, น้ำส้ม 1 แก้ว',
                hintStyle: GoogleFonts.nunito(
                    color: AppColors.textSecondary, fontSize: 14),
                filled: true,
                fillColor: isDark ? AppColorsDark.surface : AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _analyze,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'วิเคราะห์ด้วย AI 🤖',
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

// ── Fridge Picker Sheet ────────────────────────────────────────────

class _FridgePickerSheet extends StatefulWidget {
  const _FridgePickerSheet();

  @override
  State<_FridgePickerSheet> createState() => _FridgePickerSheetState();
}

class _FridgePickerSheetState extends State<_FridgePickerSheet> {
  final Set<String> _selected = {};
  bool _loading = false;

  Future<void> _analyze() async {
    if (_selected.isEmpty) return;
    final items = FridgeStore.instance.items
        .where((i) => _selected.contains(i.id))
        .toList();
    final description =
        items.map((i) => i.name).join(', ');
    setState(() => _loading = true);
    try {
      Navigator.of(context).pop();
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AnalyzingSheet(text: description),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.cardBg : Colors.white;
    final fridgeItems = FridgeStore.instance.items;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'เลือกจากตู้เย็น',
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColorsDark.textPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'เลือกวัตถุดิบที่คุณทาน',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: isDark
                        ? AppColorsDark.textSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(
            child: fridgeItems.isEmpty
                ? Center(
                    child: Text(
                      'ตู้เย็นว่างเปล่า',
                      style: GoogleFonts.nunito(
                          color: AppColors.textSecondary),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: fridgeItems.map((item) {
                        final isSelected = _selected.contains(item.id);
                        return FilterChip(
                          label: Text(
                            '${item.emoji} ${item.name}',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selected.add(item.id);
                              } else {
                                _selected.remove(item.id);
                              }
                            });
                          },
                          selectedColor: AppColors.primary,
                          checkmarkColor: Colors.white,
                          backgroundColor: isDark
                              ? AppColorsDark.surface
                              : AppColors.surface,
                        );
                      }).toList(),
                    ),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_selected.isEmpty || _loading)
                      ? null
                      : _analyze,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'วิเคราะห์ ${_selected.length} รายการ 🤖',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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

// ── Analyzing Page (for camera) ────────────────────────────────────

class _AnalyzingPage extends StatefulWidget {
  final File imageFile;
  final String method;

  const _AnalyzingPage({
    required this.imageFile,
    required this.method,
  });

  @override
  State<_AnalyzingPage> createState() => _AnalyzingPageState();
}

class _AnalyzingPageState extends State<_AnalyzingPage> {
  List<MealItem>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    try {
      final items =
          await NutritionAiService().analyzeImage(widget.imageFile);
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ข้อผิดพลาด')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('❌', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(_error!),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('กลับ'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 20),
              Text(
                'AI กำลังวิเคราะห์อาหาร...',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _ConfirmMealPage(items: _items!, imagePath: widget.imageFile.path);
  }
}

// ── Analyzing Sheet (for text/fridge) ─────────────────────────────

class _AnalyzingSheet extends StatefulWidget {
  final String text;

  const _AnalyzingSheet({required this.text});

  @override
  State<_AnalyzingSheet> createState() => _AnalyzingSheetState();
}

class _AnalyzingSheetState extends State<_AnalyzingSheet> {
  List<MealItem>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    try {
      final items = await NutritionAiService().analyzeText(widget.text);
      if (mounted) {
        setState(() => _items = items);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.cardBg : Colors.white;

    if (_error != null) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('❌', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('เกิดข้อผิดพลาด'),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ปิด'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items == null) {
      return Container(
        height: 240,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 20),
              Text(
                'AI กำลังวิเคราะห์...',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: isDark
                      ? AppColorsDark.textSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show confirm sheet
    return _ConfirmMealSheet(items: _items!);
  }
}

// ── Confirm Meal Page (after camera) ──────────────────────────────

class _ConfirmMealPage extends StatefulWidget {
  final List<MealItem> items;
  final String? imagePath;

  const _ConfirmMealPage({required this.items, this.imagePath});

  @override
  State<_ConfirmMealPage> createState() => _ConfirmMealPageState();
}

class _ConfirmMealPageState extends State<_ConfirmMealPage> {
  MealType _selectedType = MealType.lunch;
  bool _saving = false;

  MealType _guessType() {
    final hour = DateTime.now().hour;
    if (hour < 10) return MealType.breakfast;
    if (hour < 14) return MealType.lunch;
    if (hour < 20) return MealType.dinner;
    return MealType.snack;
  }

  @override
  void initState() {
    super.initState();
    _selectedType = _guessType();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final meal = MealLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      mealType: _selectedType,
      items: widget.items,
      imagePath: widget.imagePath,
    );
    await MealStore.instance.addMeal(meal);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกมื้ออาหารแล้ว! 🎉')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items
        .fold(FoodNutrition.zero, (s, i) => s + i.nutrition);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ยืนยันมื้ออาหาร',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _MealTypeSelector(
                  selected: _selectedType,
                  onChanged: (t) => setState(() => _selectedType = t),
                ),
                const SizedBox(height: 20),
                ...widget.items
                    .map((item) => _MealItemTile(item: item)),
                const SizedBox(height: 16),
                _NutritionSummary(nutrition: total),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'บันทึก ✓',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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

// ── Confirm Meal Sheet (for text/fridge) ──────────────────────────

class _ConfirmMealSheet extends StatefulWidget {
  final List<MealItem> items;

  const _ConfirmMealSheet({required this.items});

  @override
  State<_ConfirmMealSheet> createState() => _ConfirmMealSheetState();
}

class _ConfirmMealSheetState extends State<_ConfirmMealSheet> {
  MealType _selectedType = MealType.lunch;
  bool _saving = false;

  MealType _guessType() {
    final hour = DateTime.now().hour;
    if (hour < 10) return MealType.breakfast;
    if (hour < 14) return MealType.lunch;
    if (hour < 20) return MealType.dinner;
    return MealType.snack;
  }

  @override
  void initState() {
    super.initState();
    _selectedType = _guessType();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final meal = MealLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      mealType: _selectedType,
      items: widget.items,
    );
    await MealStore.instance.addMeal(meal);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกมื้ออาหารแล้ว! 🎉')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.cardBg : Colors.white;
    final total = widget.items
        .fold(FoodNutrition.zero, (s, i) => s + i.nutrition);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ยืนยันมื้ออาหาร',
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColorsDark.textPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _MealTypeSelector(
                  selected: _selectedType,
                  onChanged: (t) => setState(() => _selectedType = t),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 16),
                ...widget.items.map((item) => _MealItemTile(item: item)),
                const SizedBox(height: 16),
                _NutritionSummary(nutrition: total),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'บันทึก ✓',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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

// ── Shared widgets ─────────────────────────────────────────────────

class _MealTypeSelector extends StatelessWidget {
  final MealType selected;
  final ValueChanged<MealType> onChanged;

  const _MealTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: MealType.values.map((type) {
        final isSelected = type == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(type.emoji,
                      style: const TextStyle(fontSize: 16)),
                  Text(
                    type.label,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MealItemTile extends StatelessWidget {
  final MealItem item;

  const _MealItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColorsDark.surface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColorsDark.textPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  item.quantity,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: isDark
                        ? AppColorsDark.textSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.nutrition.calories.round()} แคล',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'P${item.nutrition.protein.round()} C${item.nutrition.carbs.round()} F${item.nutrition.fat.round()}',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  color: isDark
                      ? AppColorsDark.textSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutritionSummary extends StatelessWidget {
  final FoodNutrition nutrition;

  const _NutritionSummary({required this.nutrition});

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
      child: Column(
        children: [
          Text(
            'รวมทั้งหมด',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${nutrition.calories.round()} แคลอรี่',
            style: GoogleFonts.nunito(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SummaryItem(
                  label: '💪 โปรตีน',
                  value: '${nutrition.protein.round()}g'),
              _SummaryItem(
                  label: '🌾 คาร์บ',
                  value: '${nutrition.carbs.round()}g'),
              _SummaryItem(
                  label: '🥑 ไขมัน',
                  value: '${nutrition.fat.round()}g'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

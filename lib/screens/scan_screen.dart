import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../models/scan_result.dart';
import '../services/food_analysis_service.dart';
import '../theme/app_theme.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isScanning = false;
  String _statusMessage = 'Point camera at your fridge or food item';

  final _analysisService = FoodAnalysisService(provider: AiProvider.groq);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      _controller = CameraController(
        _cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onScanPressed() async {
    if (_isScanning || _controller == null) return;

    setState(() {
      _isScanning = true;
      _statusMessage = 'Capturing image...';
    });

    try {
      // 1. Capture photo from camera
      final XFile photo = await _controller!.takePicture();
      final imageFile = File(photo.path);

      if (!mounted) return;
      setState(() => _statusMessage = 'Analyzing with AI...');

      // 2. Send to AI vision service
      final result = await _analysisService.analyze(imageFile);

      if (!mounted) return;

      if (!result.success) {
        setState(() {
          _isScanning = false;
          _statusMessage = 'Analysis failed. Try again.';
        });
        _showErrorSnack(result.errorMessage ?? 'Unknown error');
        return;
      }

      setState(() {
        _isScanning = false;
        _statusMessage = result.items.isEmpty
            ? 'No food detected. Try again.'
            : '${result.confirmedItems.length} item(s) found!';
      });

      // 3. Show result sheet — confirmed items + uncertain items needing input
      if (result.items.isNotEmpty) {
        _showResultSheet(result);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _statusMessage = 'Something went wrong. Try again.';
      });
      _showErrorSnack(e.toString());
    }
  }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showResultSheet(ScanResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ScanResultSheet(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isInitialized && _controller != null)
            CameraPreview(_controller!)
          else
            const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          _buildOverlay(context),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
                const Text(
                  'Scan Food',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.flash_off_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Scan frame
          _ScanFrame(isScanning: _isScanning),
          const SizedBox(height: 24),
          Text(
            _statusMessage,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // Shutter button
          GestureDetector(
            onTap: _onScanPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isScanning
                    ? AppColors.accent
                    : Colors.white,
                border: Border.all(color: AppColors.accent, width: 3),
              ),
              child: _isScanning
                  ? const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 3,
                        ),
                      ),
                    )
                  : const Icon(Icons.camera_alt_rounded,
                      color: AppColors.primary, size: 30),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  final bool isScanning;
  const _ScanFrame({required this.isScanning});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        border: Border.all(
          color: isScanning ? AppColors.accent : Colors.white70,
          width: 2.5,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Corner decorations
          for (final alignment in [
            Alignment.topLeft,
            Alignment.topRight,
            Alignment.bottomLeft,
            Alignment.bottomRight,
          ])
            Align(
              alignment: alignment,
              child: _Corner(alignment: alignment),
            ),
        ],
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final Alignment alignment;
  const _Corner({required this.alignment});

  @override
  Widget build(BuildContext context) {
    final isTop = alignment == Alignment.topLeft ||
        alignment == Alignment.topRight;
    final isLeft = alignment == Alignment.topLeft ||
        alignment == Alignment.bottomLeft;

    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _CornerPainter(isTop: isTop, isLeft: isLeft),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool isTop;
  final bool isLeft;

  _CornerPainter({required this.isTop, required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final x = isLeft ? 0.0 : size.width;
    final y = isTop ? 0.0 : size.height;
    final dx = isLeft ? 16.0 : -16.0;
    final dy = isTop ? 16.0 : -16.0;

    canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// Result sheet — driven by real ScanResult from AI
// ─────────────────────────────────────────────────────────────

class _ScanResultSheet extends StatefulWidget {
  final ScanResult result;
  const _ScanResultSheet({required this.result});

  @override
  State<_ScanResultSheet> createState() => _ScanResultSheetState();
}

class _ScanResultSheetState extends State<_ScanResultSheet> {
  // Tracks user-supplied names for uncertain items (index → name)
  final Map<int, String> _userCorrections = {};

  @override
  Widget build(BuildContext context) {
    final confirmed = widget.result.confirmedItems;
    final uncertain = widget.result.uncertainItems;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  const Text('🔍 ',
                      style: TextStyle(fontSize: 20)),
                  Text(
                    'Scan Results',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.result.items.length} items',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  // ── Confirmed items ──
                  if (confirmed.isNotEmpty) ...[
                    const _SectionLabel(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Detected Items',
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    ...confirmed.map(
                      (item) => _ConfirmedItemRow(item: item),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Uncertain items — ask the user ──
                  if (uncertain.isNotEmpty) ...[
                    const _SectionLabel(
                      icon: Icons.help_outline_rounded,
                      label: 'Uncertain — Please identify',
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: 8),
                    ...uncertain.asMap().entries.map(
                          (e) => _UncertainItemRow(
                            item: e.value,
                            index: e.key,
                            onNameChanged: (name) => setState(
                              () => _userCorrections[e.key] = name,
                            ),
                          ),
                        ),
                    const SizedBox(height: 16),
                  ],

                  // ── Actions ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _onAddAll,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Add ${widget.result.items.length} item(s) to Fridge',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.accent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Scan Again',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onAddAll() {
    // Apply user corrections to uncertain items before saving
    final allItems = [...widget.result.confirmedItems];
    final uncertain = widget.result.uncertainItems;
    for (var i = 0; i < uncertain.length; i++) {
      final correction = _userCorrections[i];
      if (correction != null && correction.trim().isNotEmpty) {
        // Create a corrected copy — in a real app you'd update your store here
        allItems.add(DetectedFoodItem(
          name: correction.trim(),
          quantity: uncertain[i].quantity,
          estimatedExpiry: uncertain[i].estimatedExpiry,
          confidence: 1.0,
          isUncertain: false,
        ));
      } else {
        allItems.add(uncertain[i]); // keep as-is if user skipped
      }
    }
    // TODO: persist allItems to your local DB / state manager
    Navigator.pop(context);
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ConfirmedItemRow extends StatelessWidget {
  final DetectedFoodItem item;
  const _ConfirmedItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final pct = (item.confidence * 100).round();
    final expiryText = item.estimatedExpiry != null
        ? '~${item.daysUntilExpiry} days left'
        : 'Expiry unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.set_meal_rounded,
                  color: AppColors.primary, size: 26),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.quantity} · $expiryText',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (item.note != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.note!,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$pct%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UncertainItemRow extends StatefulWidget {
  final DetectedFoodItem item;
  final int index;
  final ValueChanged<String> onNameChanged;

  const _UncertainItemRow({
    required this.item,
    required this.index,
    required this.onNameChanged,
  });

  @override
  State<_UncertainItemRow> createState() => _UncertainItemRowState();
}

class _UncertainItemRowState extends State<_UncertainItemRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(() => widget.onNameChanged(_controller.text));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline_rounded,
                  size: 18, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                'Item ${widget.index + 1} · ${widget.item.quantity}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (widget.item.note != null) ...[
            const SizedBox(height: 4),
            Text(
              'AI note: ${widget.item.note}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'What is this item?',
              hintStyle:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              suffixIcon: const Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.primary),
            ),
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/health_metrics.dart';
import '../models/health_store.dart';
import '../models/meal_store.dart';
import '../services/lab_scan_service.dart';
import '../theme/app_theme.dart';

class LabScanScreen extends StatefulWidget {
  final CameraDescription camera;
  const LabScanScreen({super.key, required this.camera});

  @override
  State<LabScanScreen> createState() => _LabScanScreenState();
}

class _LabScanScreenState extends State<LabScanScreen> {
  late CameraController _controller;
  late Future<void> _initFuture;
  bool _analyzing = false;
  String _status = 'วางผลตรวจในกรอบ';

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
      _status = 'AI กำลังอ่านผลตรวจ...';
    });

    try {
      final xFile = await _controller.takePicture();
      final imageFile = File(xFile.path);

      final service = LabScanService();
      final report = await service.analyzeLabImage(imageFile);

      if (!mounted) return;

      if (report.metrics.isEmpty) {
        setState(() {
          _analyzing = false;
          _status = 'ไม่พบค่าตรวจในภาพ ลองใหม่อีกครั้ง';
        });
        return;
      }

      // Save report first
      await HealthStore.instance.addReport(report);

      // Show result sheet
      if (!mounted) return;
      await _showResultSheet(report);
    } catch (e) {
      if (mounted) {
        setState(() {
          _analyzing = false;
          _status = 'เกิดข้อผิดพลาด: $e';
        });
      }
    }
  }

  Future<void> _showResultSheet(LabReport report) async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LabResultSheet(
        report: report,
        onGeneratePlan: () async {
          Navigator.pop(ctx);
          await _generatePlan(report);
        },
      ),
    );
    if (mounted) {
      setState(() {
        _analyzing = false;
        _status = 'วางผลตรวจในกรอบ';
      });
    }
  }

  Future<void> _generatePlan(LabReport report) async {
    if (!mounted) return;
    setState(() {
      _analyzing = true;
      _status = 'กำลังสร้างแผนอาหาร...';
    });

    try {
      final profile = MealStore.instance.profile;
      final service = LabScanService();
      final plan = await service.generateDietaryPlan(report, profile);

      await HealthStore.instance.updateDietaryPlan(report.id, plan);

      if (mounted) {
        setState(() {
          _analyzing = false;
          _status = 'วางผลตรวจในกรอบ';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('สร้างแผนอาหารสำเร็จ! ดูได้ในหน้าสุขภาพ'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analyzing = false;
          _status = 'วางผลตรวจในกรอบ';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('สร้างแผนอาหารไม่สำเร็จ: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
        Navigator.pop(context);
      }
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
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          final size = MediaQuery.of(context).size;
          return Stack(
            children: [
              // Camera preview
              Positioned.fill(child: CameraPreview(_controller)),

              // Top bar
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      Text(
                        'สแกนผลตรวจ',
                        style: GoogleFonts.nunito(
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

              // Guide frame overlay
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: size.width * 0.88,
                      height: size.height * 0.52,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _analyzing
                              ? Colors.yellow
                              : AppColors.primaryLight,
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: _analyzing
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(
                                    color: Colors.yellow,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _status,
                                    style: GoogleFonts.nunito(
                                      color: Colors.yellow,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      shadows: const [
                                        Shadow(blurRadius: 4, color: Colors.black)
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : null,
                    ),
                    if (!_analyzing) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'วางผลตรวจในกรอบ',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Bottom shutter + status
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_analyzing)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            _status,
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 14,
                              shadows: const [
                                Shadow(blurRadius: 4, color: Colors.black)
                              ],
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTap: _analyzing ? null : _capture,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 36, top: 8),
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _analyzing
                                ? Colors.grey.shade600
                                : AppColors.primaryLight,
                            border:
                                Border.all(color: Colors.white, width: 3.5),
                          ),
                          child: _analyzing
                              ? const Padding(
                                  padding: EdgeInsets.all(18),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Center(
                                  child: Text(
                                    '📋',
                                    style: TextStyle(fontSize: 32),
                                  ),
                                ),
                        ),
                      ),
                      if (!_analyzing)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'วิเคราะห์',
                            style: GoogleFonts.nunito(
                              color: Colors.white70,
                              fontSize: 13,
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

// ── Lab result sheet ───────────────────────────────────────────────

class _LabResultSheet extends StatelessWidget {
  final LabReport report;
  final VoidCallback onGeneratePlan;

  const _LabResultSheet({
    required this.report,
    required this.onGeneratePlan,
  });

  @override
  Widget build(BuildContext context) {
    final abnormal = report.abnormalMetrics;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  // Header
                  Row(
                    children: [
                      const Text('📋', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ผลตรวจของคุณ',
                              style: GoogleFonts.nunito(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (report.labName != null)
                              Text(
                                report.labName!,
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'พบ ${report.metrics.length} ค่า · ผิดปกติ ${abnormal.length} ค่า',
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      color: abnormal.isEmpty
                          ? AppColors.good
                          : AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Abnormal section
                  if (abnormal.isNotEmpty) ...[
                    Text(
                      'ค่าที่ผิดปกติ',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...abnormal.map((m) => _MetricTile(metric: m)),
                    const SizedBox(height: 16),
                  ],

                  // All metrics
                  Text(
                    'ผลตรวจทั้งหมด',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...report.metrics.map((m) => _MetricTile(metric: m)),
                  const SizedBox(height: 24),

                  // Generate dietary plan button
                  FilledButton.icon(
                    onPressed: onGeneratePlan,
                    icon: const Text('🍽️', style: TextStyle(fontSize: 18)),
                    label: Text(
                      'สร้างแผนอาหารจากผลตรวจ',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'ข้ามการสร้างแผนอาหาร',
                      style: GoogleFonts.nunito(fontSize: 14),
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
}

class _MetricTile extends StatelessWidget {
  final HealthMetric metric;
  const _MetricTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: metric.statusColor, width: 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.nameThai,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    metric.categoryLabel,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${metric.value.toStringAsFixed(1)} ${metric.unit}',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: metric.statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    metric.statusLabel,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: metric.statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

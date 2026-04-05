import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/health_metrics.dart';
import '../models/health_store.dart';
import '../models/meal_store.dart';
import '../services/lab_scan_service.dart';
import '../theme/app_theme.dart';
import 'lab_scan_screen.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  bool _expandMetrics = false;
  bool _generatingPlan = false;

  Future<void> _openLabScan() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบกล้อง')),
        );
      }
      return;
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LabScanScreen(camera: cameras.first),
      ),
    );
  }

  Future<void> _regeneratePlan(LabReport report) async {
    setState(() => _generatingPlan = true);
    try {
      final profile = MealStore.instance.profile;
      final plan = await LabScanService().generateDietaryPlan(report, profile);
      await HealthStore.instance.updateDietaryPlan(report.id, plan);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('สร้างแผนใหม่ไม่สำเร็จ: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingPlan = false);
    }
  }

  Future<void> _deleteReport(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'ลบผลตรวจ?',
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'คุณต้องการลบผลตรวจนี้ใช่ไหม?',
          style: GoogleFonts.nunito(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await HealthStore.instance.deleteReport(id);
    }
  }

  String _formatThaiDate(DateTime date) {
    const thaiMonths = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    return '${date.day} ${thaiMonths[date.month - 1]} ${date.year + 543}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColorsDark.background : AppColors.background;
    final cardColor = isDark ? AppColorsDark.cardBg : AppColors.cardBg;
    final textPrimary = isDark ? AppColorsDark.textPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return ListenableBuilder(
      listenable: HealthStore.instance,
      builder: (context, _) {
        final store = HealthStore.instance;
        final latest = store.latestReport;
        final reports = store.reports;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            title: Text(
              'สุขภาพของฉัน',
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openLabScan,
            backgroundColor: AppColors.primary,
            icon: const Text('📋', style: TextStyle(fontSize: 20)),
            label: Text(
              'สแกนผลตรวจใหม่',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          body: latest == null
              ? _buildEmptyState(cardColor, textPrimary, textSecondary)
              : CustomScrollView(
                  slivers: [
                    // ── Latest report header ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ผลตรวจล่าสุด',
                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_rounded,
                                    size: 14, color: textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  _formatThaiDate(latest.date),
                                  style: GoogleFonts.nunito(
                                    fontSize: 13,
                                    color: textSecondary,
                                  ),
                                ),
                                if (latest.labName != null) ...[
                                  Text(
                                    ' · ${latest.labName}',
                                    style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (latest.hasAbnormal) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '⚠️ มีค่าผิดปกติ ${latest.abnormalMetrics.length} ค่า',
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // ── Metric grid ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: _MetricGrid(
                          metrics: _expandMetrics
                              ? latest.metrics
                              : latest.metrics.take(6).toList(),
                          cardColor: cardColor,
                        ),
                      ),
                    ),

                    // ── Show all toggle ──
                    if (latest.metrics.length > 6)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextButton(
                            onPressed: () => setState(
                                () => _expandMetrics = !_expandMetrics),
                            child: Text(
                              _expandMetrics
                                  ? 'ซ่อน ▲'
                                  : 'ดูทั้งหมด (${latest.metrics.length} ค่า) ▼',
                              style: GoogleFonts.nunito(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // ── Dietary plan ──
                    if (latest.dietaryPlan != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: _DietaryPlanCard(
                            report: latest,
                            cardColor: cardColor,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            generating: _generatingPlan,
                            onRegenerate: () => _regeneratePlan(latest),
                          ),
                        ),
                      )
                    else
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: _GeneratePlanCard(
                            cardColor: cardColor,
                            generating: _generatingPlan,
                            onGenerate: () => _regeneratePlan(latest),
                          ),
                        ),
                      ),

                    // ── History ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                        child: Text(
                          'ประวัติผลตรวจ',
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ),

                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final report = reports[i];
                          return Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 0, 20, 8),
                            child: _ReportHistoryTile(
                              report: report,
                              cardColor: cardColor,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              formatDate: _formatThaiDate,
                              onDelete: () => _deleteReport(report.id),
                            ),
                          );
                        },
                        childCount: reports.length,
                      ),
                    ),

                    const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(
      Color cardColor, Color textPrimary, Color textSecondary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🩺', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 20),
            Text(
              'ยังไม่มีผลตรวจ',
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'สแกนผลตรวจร่างกายของคุณเพื่อรับแผนอาหารเฉพาะตัวจาก AI',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 15,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _openLabScan,
              icon: const Text('📋', style: TextStyle(fontSize: 20)),
              label: Text(
                'สแกนผลตรวจเลย',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Metric Grid ────────────────────────────────────────────────────

class _MetricGrid extends StatelessWidget {
  final List<HealthMetric> metrics;
  final Color cardColor;

  const _MetricGrid({required this.metrics, required this.cardColor});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.7,
      ),
      itemCount: metrics.length,
      itemBuilder: (_, i) => _MetricCard(metric: metrics[i], cardColor: cardColor),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final HealthMetric metric;
  final Color cardColor;

  const _MetricCard({required this.metric, required this.cardColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: metric.statusColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            metric.nameThai,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  metric.value.toStringAsFixed(1),
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                metric.unit,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: metric.statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              metric.statusLabel,
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: metric.statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dietary Plan Card ─────────────────────────────────────────────

class _DietaryPlanCard extends StatelessWidget {
  final LabReport report;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final bool generating;
  final VoidCallback onRegenerate;

  const _DietaryPlanCard({
    required this.report,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.generating,
    required this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    final lines = report.dietaryPlan!.split('\n');

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                const Text('🍽️', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'แผนอาหารจากผลเลือด',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ),
                if (generating)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: onRegenerate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'สร้างใหม่',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 20, indent: 16, endIndent: 16),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines.map((line) => _buildLine(line, textPrimary, textSecondary)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(String line, Color textPrimary, Color textSecondary) {
    if (line.trim().isEmpty) return const SizedBox(height: 6);

    // Bold headers: lines starting with ** or ending with **
    final isBold = line.startsWith('**') ||
        line.contains('**') ||
        line.startsWith('#') ||
        RegExp(r'^\d+\.').hasMatch(line.trim());

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        line.replaceAll('**', '').replaceAll('#', '').trim(),
        style: GoogleFonts.nunito(
          fontSize: isBold ? 14 : 13,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
          color: isBold ? textPrimary : textSecondary,
          height: 1.5,
        ),
      ),
    );
  }
}

class _GeneratePlanCard extends StatelessWidget {
  final Color cardColor;
  final bool generating;
  final VoidCallback onGenerate;

  const _GeneratePlanCard({
    required this.cardColor,
    required this.generating,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          const Text('🍽️', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          Text(
            'ยังไม่มีแผนอาหาร',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'สร้างแผนอาหารเฉพาะตัวจากผลเลือดของคุณ',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: generating ? null : onGenerate,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: generating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'สร้างแผนอาหาร',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Report History Tile ───────────────────────────────────────────

class _ReportHistoryTile extends StatelessWidget {
  final LabReport report;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final String Function(DateTime) formatDate;
  final VoidCallback onDelete;

  const _ReportHistoryTile({
    required this.report,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.formatDate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(report.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // HealthStore.deleteReport handles removal via notifyListeners
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🩺', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatDate(report.date),
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  if (report.labName != null)
                    Text(
                      report.labName!,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  Text(
                    '${report.metrics.length} ค่าตรวจ',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (report.hasAbnormal)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '⚠️ ${report.abnormalMetrics.length}',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

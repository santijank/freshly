import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../theme/app_theme.dart';

class FreshnessGauge extends StatelessWidget {
  final int score; // 0–100

  const FreshnessGauge({super.key, required this.score});

  Color get _scoreColor {
    if (score >= 70) return AppColors.good;
    if (score >= 40) return AppColors.warning;
    return AppColors.danger;
  }

  String get _label {
    if (score >= 70) return 'Mostly Fresh';
    if (score >= 40) return 'Use Soon';
    return 'Expiring!';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Freshness Score',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _label,
                    style: TextStyle(
                      fontSize: 13,
                      color: _scoreColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              CircularPercentIndicator(
                radius: 56,
                lineWidth: 10,
                percent: score / 100,
                animation: true,
                animationDuration: 800,
                circularStrokeCap: CircularStrokeCap.round,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: _scoreColor,
                      ),
                    ),
                    Text(
                      'pts',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                progressColor: _scoreColor,
                backgroundColor: const Color(0xFFE0E0E0),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStats(context),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _Stat(label: 'Items', value: '12', color: AppColors.primary),
        _Divider(),
        _Stat(label: 'Expiring', value: '3', color: AppColors.warning),
        _Divider(),
        _Stat(label: 'Expired', value: '1', color: AppColors.danger),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.accent.withOpacity(0.5),
    );
  }
}

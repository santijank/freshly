import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../theme/app_theme.dart';

class ExpiringCard extends StatelessWidget {
  final FoodItem item;

  const ExpiringCard({super.key, required this.item});

  Color get _statusColor {
    switch (item.status) {
      case FreshnessStatus.danger:
        return AppColors.danger;
      case FreshnessStatus.warning:
        return AppColors.warning;
      case FreshnessStatus.good:
        return AppColors.good;
    }
  }

  String get _daysText {
    if (item.daysLeft == 0) return 'Today!';
    if (item.daysLeft == 1) return '1 day left';
    return '${item.daysLeft} days left';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _statusColor.withOpacity(0.3),
          width: 1.5,
        ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            item.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _daysText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _statusColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: item.freshnessScore / 100,
            backgroundColor: const Color(0xFFE0E0E0),
            valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
            borderRadius: BorderRadius.circular(4),
            minHeight: 4,
          ),
        ],
      ),
    );
  }
}

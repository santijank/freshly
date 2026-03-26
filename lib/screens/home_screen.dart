import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../theme/app_theme.dart';
import '../widgets/expiring_card.dart';
import '../widgets/freshness_gauge.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  List<FoodItem> get _expiringSoon =>
      sampleItems.where((i) => i.daysLeft <= 5).toList()
        ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

  int get _overallScore {
    if (sampleItems.isEmpty) return 0;
    return sampleItems
            .map((i) => i.freshnessScore)
            .reduce((a, b) => a + b) ~/
        sampleItems.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FreshnessGauge(score: _overallScore),
              ),
            ),
            SliverToBoxAdapter(child: _buildExpiringSoon(context)),
            SliverToBoxAdapter(child: _buildAllItems(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'สวัสดีตอนเช้า! 🌿',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 2),
              Text(
                'ตู้เย็นของฉัน',
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ],
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiringSoon(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ใกล้หมดอายุ',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'ดูทั้งหมด',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 20),
              itemCount: _expiringSoon.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) =>
                  ExpiringCard(item: _expiringSoon[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllItems(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('รายการทั้งหมด', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...sampleItems.map((item) => _ItemRow(item: item)),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final FoodItem item;

  const _ItemRow({required this.item});

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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.daysLeft == 0
                      ? 'หมดอายุวันนี้'
                      : 'หมดอายุใน ${item.daysLeft} วัน',
                  style: TextStyle(fontSize: 12, color: _statusColor),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${item.freshnessScore}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

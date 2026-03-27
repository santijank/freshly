import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../models/fridge_store.dart';
import '../theme/app_theme.dart';
import '../widgets/expiring_card.dart';
import '../widgets/freshness_gauge.dart';

Future<void> _confirmReset(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('รีเซ็ตตู้เย็น?',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      content: const Text(
        'รายการอาหารทั้งหมดจะถูกลบออก ไม่สามารถกู้คืนได้',
        style: TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('ยกเลิก',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('รีเซ็ต'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    FridgeStore.instance.clearAll();
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FridgeStore.instance,
      builder: (context, _) {
        final items = FridgeStore.instance.items;
        final expiringSoon = items
            .where((i) => i.daysLeft <= 5)
            .toList()
          ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
        final overallScore = items.isEmpty
            ? 0
            : items.map((i) => i.freshnessScore).reduce((a, b) => a + b) ~/
                items.length;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FreshnessGauge(score: overallScore),
                  ),
                ),
                SliverToBoxAdapter(
                    child: _buildExpiringSoon(context, expiringSoon)),
                SliverToBoxAdapter(child: _buildAllItems(context, items)),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        );
      },
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
          Row(
            children: [
              GestureDetector(
                onTap: () => _confirmReset(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.restart_alt_rounded,
                    color: AppColors.danger,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
        ],
      ),
    );
  }

  Widget _buildExpiringSoon(
      BuildContext context, List<FoodItem> expiringSoon) {
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
          if (expiringSoon.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 12, right: 20),
              child: Text(
                'ไม่มีรายการใกล้หมดอายุ 🎉',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 20),
                itemCount: expiringSoon.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    ExpiringCard(item: expiringSoon[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAllItems(BuildContext context, List<FoodItem> items) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('รายการทั้งหมด', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text(
              'ยังไม่มีรายการ — กดสแกนเพื่อเพิ่มอาหาร',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            ...items.map((item) => _ItemRow(item: item)),
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

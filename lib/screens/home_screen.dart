import 'package:flutter/material.dart';
import '../main.dart';
import '../models/food_item.dart';
import '../models/fridge_store.dart';
import '../theme/app_theme.dart';
import '../widgets/expiring_card.dart';
import '../widgets/freshness_gauge.dart';

Future<void> _confirmReset(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('รีเซ็ตตู้เย็น?',
          style: TextStyle(fontWeight: FontWeight.w700)),
      content: const Text(
        'รายการอาหารทั้งหมดจะถูกลบออก ไม่สามารถกู้คืนได้',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('ยกเลิก'),
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

void _showAddItemSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const _AddItemSheet(),
  );
}

void _showEditItemSheet(BuildContext context, FoodItem item) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _EditItemSheet(item: item),
  );
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
                SliverToBoxAdapter(
                    child: _buildAllItems(context, List.from(items))),
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
              _HeaderButton(
                icon: Icons.dark_mode_outlined,
                color: AppColors.primary,
                bgColor: AppColors.surface,
                onTap: () => FreshlyApp.of(context).toggleTheme(),
              ),
              const SizedBox(width: 8),
              _HeaderButton(
                icon: Icons.restart_alt_rounded,
                color: AppColors.danger,
                bgColor: AppColors.danger,
                bgOpacity: 0.1,
                onTap: () => _confirmReset(context),
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
    // Group by category
    final Map<FoodCategory, List<FoodItem>> grouped = {};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    // Sort categories so non-empty ones appear in a sensible order
    final orderedCategories = FoodCategory.values
        .where((c) => grouped.containsKey(c))
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('รายการทั้งหมด',
                  style: Theme.of(context).textTheme.titleLarge),
              GestureDetector(
                onTap: () => _showAddItemSheet(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text(
              'ยังไม่มีรายการ — กดสแกนหรือ + เพื่อเพิ่มอาหาร',
              style: TextStyle(color: AppColors.textSecondary),
            )
          else
            ...orderedCategories.map((category) {
              final categoryItems = grouped[category]!;
              return _CategorySection(
                category: category,
                items: categoryItems,
                onEdit: (item) => _showEditItemSheet(context, item),
              );
            }),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final double bgOpacity;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.color,
    required this.bgColor,
    this.bgOpacity = 1.0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bgColor.withOpacity(bgOpacity),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final FoodCategory category;
  final List<FoodItem> items;
  final void Function(FoodItem) onEdit;

  const _CategorySection({
    required this.category,
    required this.items,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    // Use a temporary FoodItem to get label/emoji without duplicating logic
    final dummy = FoodItem(
      id: '',
      name: '',
      emoji: '',
      expiryDate: DateTime.now(),
      freshnessScore: 0,
      category: category,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            children: [
              Text(dummy.categoryEmoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                dummy.categoryLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${items.length}',
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
        ...items.map(
          (item) => _DismissibleItemRow(
            item: item,
            onEdit: onEdit,
          ),
        ),
      ],
    );
  }
}

class _DismissibleItemRow extends StatelessWidget {
  final FoodItem item;
  final void Function(FoodItem) onEdit;

  const _DismissibleItemRow({required this.item, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 26),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('ลบ "${item.name}"?',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            content: const Text('รายการนี้จะถูกลบออกจากตู้เย็น'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('ยกเลิก'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('ลบ'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => FridgeStore.instance.removeItem(item.id),
      child: GestureDetector(
        onTap: () => onEdit(item),
        child: _ItemRow(item: item),
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
        color: Theme.of(context).cardTheme.color ?? AppColors.cardBg,
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
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.daysLeft == 0
                      ? 'หมดอายุวันนี้'
                      : item.daysLeft < 0
                          ? 'หมดอายุแล้ว'
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

// ── Add Item Bottom Sheet ───────────────────────────────────────────

class _AddItemSheet extends StatefulWidget {
  const _AddItemSheet();

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _nameController = TextEditingController();
  FoodCategory _selectedCategory = FoodCategory.other;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('th', 'TH'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    FridgeStore.instance.addManual(
      name,
      category: _selectedCategory,
      expiryDate: _selectedDate,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('เพิ่มรายการใหม่',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'ชื่ออาหาร',
              hintText: 'เช่น แครอท, นมสด, ไข่ไก่',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.edit_outlined),
            ),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 16),
          Text('หมวดหมู่',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          _CategoryChips(
            selected: _selectedCategory,
            onSelected: (c) => setState(() => _selectedCategory = c),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'หมดอายุ: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _saving ? 'กำลังบันทึก...' : 'เพิ่ม',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Edit Item Bottom Sheet ───────────────────────────────────────────

class _EditItemSheet extends StatefulWidget {
  final FoodItem item;

  const _EditItemSheet({required this.item});

  @override
  State<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends State<_EditItemSheet> {
  late final TextEditingController _nameController;
  late FoodCategory _selectedCategory;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _selectedCategory = widget.item.category;
    _selectedDate = widget.item.expiryDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(DateTime.now())
          ? DateTime.now()
          : _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    FridgeStore.instance.updateItem(
      widget.item.id,
      name: name,
      category: _selectedCategory,
      expiryDate: _selectedDate,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('แก้ไขรายการ',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'ชื่ออาหาร',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.edit_outlined),
            ),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 16),
          Text('หมวดหมู่',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          _CategoryChips(
            selected: _selectedCategory,
            onSelected: (c) => setState(() => _selectedCategory = c),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'หมดอายุ: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'บันทึก',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category Chips ───────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  final FoodCategory selected;
  final ValueChanged<FoodCategory> onSelected;

  const _CategoryChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: FoodCategory.values.map((c) {
        final dummy = FoodItem(
          id: '',
          name: '',
          emoji: '',
          expiryDate: DateTime.now(),
          freshnessScore: 0,
          category: c,
        );
        final isSelected = selected == c;
        return GestureDetector(
          onTap: () => onSelected(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
            ),
            child: Text(
              '${dummy.categoryEmoji} ${dummy.categoryLabel}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}


import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../models/fridge_store.dart';
import '../theme/app_theme.dart';

class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  static const List<_RecipeData> _recipes = [
    _RecipeData(
      emoji: '🥗',
      title: 'สลัดผักโขม',
      tag: 'ใช้ของใกล้หมดอายุ',
      time: '10 นาที',
      urgent: true,
      ingredients: ['ผักโขม', 'มะเขือเทศ', 'แตงกวา', 'ไข่', 'น้ำมัน', 'มะนาว'],
      ingredientKeywords: ['ผักโขม', 'มะเขือ', 'แตงกวา', 'ไข่', 'น้ำมัน', 'มะนาว', 'ผัก'],
    ),
    _RecipeData(
      emoji: '🍲',
      title: 'ผัดผักรวม',
      tag: 'ง่ายและรวดเร็ว',
      time: '20 นาที',
      urgent: false,
      ingredients: ['ผักรวม', 'น้ำมันหอย', 'กระเทียม', 'ซีอิ๊ว'],
      ingredientKeywords: ['ผัก', 'กระเทียม', 'น้ำมัน', 'หมู', 'ไก่', 'เนื้อ', 'บร็อคโคลี', 'แครอท', 'ข้าวโพด'],
    ),
    _RecipeData(
      emoji: '🥤',
      title: 'กรีนสมูทตี้',
      tag: 'ใช้ของใกล้หมดอายุ',
      time: '5 นาที',
      urgent: true,
      ingredients: ['ผักโขม', 'กล้วย', 'นม', 'น้ำผึ้ง'],
      ingredientKeywords: ['ผักโขม', 'กล้วย', 'นม', 'โยเกิร์ต', 'ผลไม้', 'แอปเปิ้ล', 'สตรอว์เบอร์รี'],
    ),
    _RecipeData(
      emoji: '🍳',
      title: 'อะโวคาโดโทสต์',
      tag: 'อาหารเช้า',
      time: '8 นาที',
      urgent: false,
      ingredients: ['อะโวคาโด', 'ขนมปัง', 'ไข่', 'มะนาว'],
      ingredientKeywords: ['อะโวคาโด', 'ขนมปัง', 'ไข่', 'มะนาว', 'เนย'],
    ),
    _RecipeData(
      emoji: '🥣',
      title: 'โยเกิร์ตโบวล์',
      tag: 'ใช้ของใกล้หมดอายุ',
      time: '3 นาที',
      urgent: true,
      ingredients: ['โยเกิร์ต', 'ผลไม้', 'น้ำผึ้ง'],
      ingredientKeywords: ['โยเกิร์ต', 'สตรอว์เบอร์รี', 'กล้วย', 'องุ่น', 'ผลไม้', 'แอปเปิ้ล', 'มะม่วง'],
    ),
    _RecipeData(
      emoji: '🍜',
      title: 'ข้าวผัดไข่',
      tag: 'อาหารง่าย',
      time: '15 นาที',
      urgent: false,
      ingredients: ['ข้าว', 'ไข่', 'ซีอิ๊ว', 'น้ำมัน', 'กระเทียม'],
      ingredientKeywords: ['ไข่', 'ข้าว', 'กระเทียม', 'น้ำมัน', 'ผัก', 'หมู', 'ไก่'],
    ),
    _RecipeData(
      emoji: '🥚',
      title: 'ไข่ดาวผักโขม',
      tag: 'อาหารเช้า',
      time: '7 นาที',
      urgent: false,
      ingredients: ['ไข่', 'ผักโขม', 'เนย', 'เกลือ'],
      ingredientKeywords: ['ไข่', 'ผักโขม', 'เนย', 'ผัก'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FridgeStore.instance,
      builder: (context, _) {
        final fridgeItems = FridgeStore.instance.items;
        final expiringItems = fridgeItems.where((i) => i.daysLeft <= 5).toList();

        // นับสูตรที่ match กับของในตู้เย็น
        final matchingRecipes = _recipes
            .where((r) => _getMatchedItems(r, fridgeItems).isNotEmpty)
            .length;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverToBoxAdapter(
                  child: _buildSuggestionBanner(
                      context, matchingRecipes, expiringItems.length),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _RecipeItem(
                        recipe: _recipes[index],
                        matchedItems: _getMatchedItems(_recipes[index], fridgeItems),
                      ),
                      childCount: _recipes.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// หา fridge items ที่ตรงกับส่วนผสมของสูตรนี้
  List<FoodItem> _getMatchedItems(_RecipeData recipe, List<FoodItem> fridgeItems) {
    final matched = <FoodItem>[];
    for (final item in fridgeItems) {
      final itemName = item.name.toLowerCase();
      for (final keyword in recipe.ingredientKeywords) {
        if (itemName.contains(keyword.toLowerCase())) {
          matched.add(item);
          break;
        }
      }
    }
    return matched;
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('สูตรอาหาร',
              style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 4),
          Text('จากอาหารในตู้เย็นของคุณ',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildSuggestionBanner(
      BuildContext context, int matchingCount, int expiringCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Text('🌿', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ใช้ก่อนหมดอายุ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    matchingCount > 0
                        ? '$matchingCount สูตรใช้วัตถุดิบในตู้เย็นของคุณ'
                        : 'เพิ่มอาหารในตู้เย็นเพื่อดูสูตรที่เหมาะ',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  if (expiringCount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '⚠️ มี $expiringCount รายการใกล้หมดอายุ',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Data model ─────────────────────────────────────────────

class _RecipeData {
  final String emoji;
  final String title;
  final String tag;
  final String time;
  final bool urgent;
  final List<String> ingredients;
  final List<String> ingredientKeywords;

  const _RecipeData({
    required this.emoji,
    required this.title,
    required this.tag,
    required this.time,
    required this.urgent,
    required this.ingredients,
    required this.ingredientKeywords,
  });
}

// ── Recipe card widget ──────────────────────────────────────

class _RecipeItem extends StatelessWidget {
  final _RecipeData recipe;
  final List<FoodItem> matchedItems;

  const _RecipeItem({
    required this.recipe,
    required this.matchedItems,
  });

  @override
  Widget build(BuildContext context) {
    final hasMatch = matchedItems.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: hasMatch
            ? Border.all(
                color: AppColors.primary.withOpacity(0.3), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── หัวสูตร ──
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(recipe.emoji,
                      style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (recipe.urgent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              recipe.tag,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning,
                              ),
                            ),
                          )
                        else
                          Text(recipe.tag,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(height: 2),
                  Text(recipe.time,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),

          // ── วัตถุดิบในตู้เย็น ──
          if (hasMatch) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.kitchen_rounded,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text(
                  'มีในตู้เย็น:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: matchedItems.map((item) {
                final isExpiring = item.daysLeft <= 5;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isExpiring
                        ? AppColors.warning.withOpacity(0.12)
                        : AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isExpiring
                          ? AppColors.warning.withOpacity(0.3)
                          : AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.emoji,
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isExpiring
                              ? AppColors.warning
                              : AppColors.primary,
                        ),
                      ),
                      if (isExpiring) ...[
                        const SizedBox(width: 4),
                        Text(
                          '(${item.daysLeft == 0 ? 'วันนี้' : '${item.daysLeft}ว.'})',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.warning),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            // ── วัตถุดิบที่ต้องใช้ (ยังไม่มีในตู้เย็น) ──
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: recipe.ingredients.map((ing) => Text(
                '• $ing',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

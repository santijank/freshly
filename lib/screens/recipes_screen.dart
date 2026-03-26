import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  static const List<_RecipeCard> _recipes = [
    _RecipeCard(
      emoji: '🥗',
      title: 'Spinach Salad',
      tag: 'Uses expiring items',
      time: '10 min',
      urgent: true,
    ),
    _RecipeCard(
      emoji: '🍲',
      title: 'Veggie Stir-fry',
      tag: 'Quick & Easy',
      time: '20 min',
      urgent: false,
    ),
    _RecipeCard(
      emoji: '🥤',
      title: 'Green Smoothie',
      tag: 'Uses expiring items',
      time: '5 min',
      urgent: true,
    ),
    _RecipeCard(
      emoji: '🍳',
      title: 'Avocado Toast',
      tag: 'Breakfast',
      time: '8 min',
      urgent: false,
    ),
    _RecipeCard(
      emoji: '🥣',
      title: 'Yogurt Bowl',
      tag: 'Uses expiring items',
      time: '3 min',
      urgent: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildSuggestionBanner(context)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _RecipeItem(recipe: _recipes[index]),
                  childCount: _recipes.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recipes',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Based on what\'s in your fridge',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionBanner(BuildContext context) {
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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Use Before They Expire',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '3 recipes match your expiring items',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeCard {
  final String emoji;
  final String title;
  final String tag;
  final String time;
  final bool urgent;

  const _RecipeCard({
    required this.emoji,
    required this.title,
    required this.tag,
    required this.time,
    required this.urgent,
  });
}

class _RecipeItem extends StatelessWidget {
  final _RecipeCard recipe;

  const _RecipeItem({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                recipe.emoji,
                style: const TextStyle(fontSize: 28),
              ),
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
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (recipe.urgent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
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
                      Text(
                        recipe.tag,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 2),
              Text(
                recipe.time,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

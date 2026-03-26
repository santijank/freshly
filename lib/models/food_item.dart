class FoodItem {
  final String id;
  final String name;
  final String emoji;
  final DateTime expiryDate;
  final int freshnessScore; // 0–100

  FoodItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.expiryDate,
    required this.freshnessScore,
  });

  int get daysLeft => expiryDate.difference(DateTime.now()).inDays;

  FreshnessStatus get status {
    if (daysLeft <= 1) return FreshnessStatus.danger;
    if (daysLeft <= 3) return FreshnessStatus.warning;
    return FreshnessStatus.good;
  }
}

enum FreshnessStatus { good, warning, danger }

final List<FoodItem> sampleItems = [
  FoodItem(
    id: '1',
    name: 'Spinach',
    emoji: '🥬',
    expiryDate: DateTime.now().add(const Duration(days: 1)),
    freshnessScore: 25,
  ),
  FoodItem(
    id: '2',
    name: 'Greek Yogurt',
    emoji: '🥛',
    expiryDate: DateTime.now().add(const Duration(days: 3)),
    freshnessScore: 55,
  ),
  FoodItem(
    id: '3',
    name: 'Avocado',
    emoji: '🥑',
    expiryDate: DateTime.now().add(const Duration(days: 2)),
    freshnessScore: 40,
  ),
  FoodItem(
    id: '4',
    name: 'Strawberries',
    emoji: '🍓',
    expiryDate: DateTime.now().add(const Duration(days: 5)),
    freshnessScore: 78,
  ),
  FoodItem(
    id: '5',
    name: 'Eggs',
    emoji: '🥚',
    expiryDate: DateTime.now().add(const Duration(days: 14)),
    freshnessScore: 92,
  ),
];

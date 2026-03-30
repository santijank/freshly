enum FoodCategory {
  vegetable,
  fruit,
  meat,
  dairy,
  beverage,
  sauce,
  grain,
  snack,
  other,
}

class FoodItem {
  final String id;
  final String name;
  final String emoji;
  final DateTime expiryDate;
  final int freshnessScore; // 0–100
  final FoodCategory category;

  FoodItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.expiryDate,
    required this.freshnessScore,
    this.category = FoodCategory.other,
  });

  int get daysLeft => expiryDate.difference(DateTime.now()).inDays;

  FreshnessStatus get status {
    if (daysLeft <= 1) return FreshnessStatus.danger;
    if (daysLeft <= 3) return FreshnessStatus.warning;
    return FreshnessStatus.good;
  }

  String get categoryLabel {
    switch (category) {
      case FoodCategory.vegetable:
        return 'ผัก';
      case FoodCategory.fruit:
        return 'ผลไม้';
      case FoodCategory.meat:
        return 'เนื้อสัตว์';
      case FoodCategory.dairy:
        return 'นมและผลิตภัณฑ์';
      case FoodCategory.beverage:
        return 'เครื่องดื่ม';
      case FoodCategory.sauce:
        return 'ซอสและเครื่องปรุง';
      case FoodCategory.grain:
        return 'ธัญพืชและแป้ง';
      case FoodCategory.snack:
        return 'ขนมและของกินเล่น';
      case FoodCategory.other:
        return 'อื่นๆ';
    }
  }

  String get categoryEmoji {
    switch (category) {
      case FoodCategory.vegetable:
        return '🥦';
      case FoodCategory.fruit:
        return '🍎';
      case FoodCategory.meat:
        return '🥩';
      case FoodCategory.dairy:
        return '🥛';
      case FoodCategory.beverage:
        return '🧃';
      case FoodCategory.sauce:
        return '🫙';
      case FoodCategory.grain:
        return '🌾';
      case FoodCategory.snack:
        return '🍿';
      case FoodCategory.other:
        return '🍽️';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'expiryDate': expiryDate.toIso8601String(),
        'freshnessScore': freshnessScore,
        'category': category.index,
      };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        expiryDate: DateTime.parse(json['expiryDate'] as String),
        freshnessScore: json['freshnessScore'] as int,
        category: FoodCategory.values[json['category'] as int? ?? 8],
      );

  FoodItem copyWith({
    String? id,
    String? name,
    String? emoji,
    DateTime? expiryDate,
    int? freshnessScore,
    FoodCategory? category,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      expiryDate: expiryDate ?? this.expiryDate,
      freshnessScore: freshnessScore ?? this.freshnessScore,
      category: category ?? this.category,
    );
  }
}

enum FreshnessStatus { good, warning, danger }

final List<FoodItem> sampleItems = [
  FoodItem(
    id: '1',
    name: 'ผักโขม',
    emoji: '🥬',
    expiryDate: DateTime.now().add(const Duration(days: 1)),
    freshnessScore: 25,
    category: FoodCategory.vegetable,
  ),
  FoodItem(
    id: '2',
    name: 'โยเกิร์ตกรีก',
    emoji: '🥛',
    expiryDate: DateTime.now().add(const Duration(days: 3)),
    freshnessScore: 55,
    category: FoodCategory.dairy,
  ),
  FoodItem(
    id: '3',
    name: 'อะโวคาโด',
    emoji: '🥑',
    expiryDate: DateTime.now().add(const Duration(days: 2)),
    freshnessScore: 40,
    category: FoodCategory.fruit,
  ),
  FoodItem(
    id: '4',
    name: 'สตรอว์เบอร์รี',
    emoji: '🍓',
    expiryDate: DateTime.now().add(const Duration(days: 5)),
    freshnessScore: 78,
    category: FoodCategory.fruit,
  ),
  FoodItem(
    id: '5',
    name: 'ไข่ไก่',
    emoji: '🥚',
    expiryDate: DateTime.now().add(const Duration(days: 14)),
    freshnessScore: 92,
    category: FoodCategory.dairy,
  ),
];

class FoodNutrition {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const FoodNutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  FoodNutrition operator +(FoodNutrition other) => FoodNutrition(
        calories: calories + other.calories,
        protein: protein + other.protein,
        carbs: carbs + other.carbs,
        fat: fat + other.fat,
      );

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };

  factory FoodNutrition.fromJson(Map<String, dynamic> json) => FoodNutrition(
        calories: (json['calories'] as num).toDouble(),
        protein: (json['protein'] as num).toDouble(),
        carbs: (json['carbs'] as num).toDouble(),
        fat: (json['fat'] as num).toDouble(),
      );

  static const zero = FoodNutrition(calories: 0, protein: 0, carbs: 0, fat: 0);
}

class MealItem {
  final String id;
  final String name;
  final String emoji;
  final String quantity;
  final FoodNutrition nutrition;

  const MealItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.quantity,
    required this.nutrition,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'quantity': quantity,
        'nutrition': nutrition.toJson(),
      };

  factory MealItem.fromJson(Map<String, dynamic> json) => MealItem(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        quantity: json['quantity'] as String,
        nutrition: FoodNutrition.fromJson(
            json['nutrition'] as Map<String, dynamic>),
      );
}

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeExtension on MealType {
  String get label {
    switch (this) {
      case MealType.breakfast:
        return 'เช้า';
      case MealType.lunch:
        return 'กลางวัน';
      case MealType.dinner:
        return 'เย็น';
      case MealType.snack:
        return 'ว่าง';
    }
  }

  String get emoji {
    switch (this) {
      case MealType.breakfast:
        return '🌅';
      case MealType.lunch:
        return '☀️';
      case MealType.dinner:
        return '🌙';
      case MealType.snack:
        return '🍿';
    }
  }
}

class MealLog {
  final String id;
  final DateTime date;
  final MealType mealType;
  final List<MealItem> items;
  final String? imagePath;

  const MealLog({
    required this.id,
    required this.date,
    required this.mealType,
    required this.items,
    this.imagePath,
  });

  FoodNutrition get totalNutrition =>
      items.fold(FoodNutrition.zero, (sum, item) => sum + item.nutrition);

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'mealType': mealType.index,
        'items': items.map((i) => i.toJson()).toList(),
        'imagePath': imagePath,
      };

  factory MealLog.fromJson(Map<String, dynamic> json) => MealLog(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        mealType: MealType.values[json['mealType'] as int],
        items: (json['items'] as List<dynamic>)
            .map((i) => MealItem.fromJson(i as Map<String, dynamic>))
            .toList(),
        imagePath: json['imagePath'] as String?,
      );
}

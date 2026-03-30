import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'food_item.dart';
import 'scan_result.dart';

/// Persistent store — single source of truth for fridge items.
class FridgeStore extends ChangeNotifier {
  FridgeStore._();
  static final FridgeStore instance = FridgeStore._();

  static const _kKey = 'fridge_items_v1';

  final List<FoodItem> _items = [];
  bool _loaded = false;

  /// Load from disk once; call in main() before runApp.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kKey);
    if (raw != null && raw.isNotEmpty) {
      _items.addAll(
        raw.map((s) => FoodItem.fromJson(jsonDecode(s) as Map<String, dynamic>)),
      );
    } else {
      _items.addAll(sampleItems); // first launch
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kKey,
      _items.map((i) => jsonEncode(i.toJson())).toList(),
    );
  }

  List<FoodItem> get items => List.unmodifiable(_items);

  /// Convert [DetectedFoodItem]s from a scan and add them to the fridge.
  void addFromScan(List<DetectedFoodItem> detected) {
    var idCounter = DateTime.now().millisecondsSinceEpoch;
    for (final d in detected) {
      final expiry = d.estimatedExpiry ??
          DateTime.now().add(const Duration(days: 7)); // fallback: 1 week
      final daysLeft = expiry.difference(DateTime.now()).inDays.clamp(0, 365);
      final score = _freshnessScore(daysLeft);
      final category = _categoryForFood(d.name);

      _items.add(FoodItem(
        id: '${idCounter++}',
        name: d.name,
        emoji: _emojiForFood(d.name),
        expiryDate: expiry,
        freshnessScore: score,
        category: category,
      ));
    }
    notifyListeners();
    _save();
  }

  /// Add an item manually without scanning.
  void addManual(
    String name, {
    FoodCategory? category,
    DateTime? expiryDate,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final expiry = expiryDate ?? DateTime.now().add(const Duration(days: 7));
    final daysLeft = expiry.difference(DateTime.now()).inDays.clamp(0, 365);
    final score = _freshnessScore(daysLeft);
    final detectedCategory = category ?? _categoryForFood(name);

    _items.add(FoodItem(
      id: id,
      name: name,
      emoji: _emojiForFood(name),
      expiryDate: expiry,
      freshnessScore: score,
      category: detectedCategory,
    ));
    notifyListeners();
    _save();
  }

  /// Edit an existing item by id.
  void updateItem(
    String id, {
    String? name,
    FoodCategory? category,
    DateTime? expiryDate,
  }) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) return;

    final existing = _items[index];
    final newName = name ?? existing.name;
    final newExpiry = expiryDate ?? existing.expiryDate;
    final daysLeft = newExpiry.difference(DateTime.now()).inDays.clamp(0, 365);
    final newScore = _freshnessScore(daysLeft);
    final newCategory = category ?? existing.category;

    _items[index] = existing.copyWith(
      name: newName,
      emoji: name != null ? _emojiForFood(newName) : null,
      expiryDate: newExpiry,
      freshnessScore: newScore,
      category: newCategory,
    );
    notifyListeners();
    _save();
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
    _save();
  }

  void clearAll() {
    _items.clear();
    notifyListeners();
    _save();
  }

  // ── helpers ─────────────────────────────────────────────────

  int _freshnessScore(int daysLeft) {
    if (daysLeft > 14) return 92;
    if (daysLeft > 7) return 75;
    if (daysLeft > 3) return 55;
    if (daysLeft > 1) return 30;
    return 10;
  }

  FoodCategory _categoryForFood(String name) {
    final n = name.toLowerCase();

    // Vegetables
    if (n.contains('ผัก') ||
        n.contains('กะหล่ำ') ||
        n.contains('แครอท') ||
        n.contains('บร็อคโคลี') ||
        n.contains('broccoli') ||
        n.contains('carrot') ||
        n.contains('spinach') ||
        n.contains('ผักโขม') ||
        n.contains('แตงกวา') ||
        n.contains('cucumber') ||
        n.contains('ข้าวโพด') ||
        n.contains('corn') ||
        n.contains('มะเขือ') ||
        n.contains('tomato') ||
        n.contains('lettuce') ||
        n.contains('ผักกาด') ||
        n.contains('celery') ||
        n.contains('เซเลอรี') ||
        n.contains('หัวหอม') ||
        n.contains('onion') ||
        n.contains('กระเทียม') ||
        n.contains('garlic') ||
        n.contains('เห็ด') ||
        n.contains('mushroom') ||
        n.contains('cabbage') ||
        n.contains('vegetable') ||
        n.contains('veggie')) {
      return FoodCategory.vegetable;
    }

    // Fruits
    if (n.contains('ผลไม้') ||
        n.contains('fruit') ||
        n.contains('แอปเปิ้ล') ||
        n.contains('apple') ||
        n.contains('กล้วย') ||
        n.contains('banana') ||
        n.contains('ส้ม') ||
        n.contains('orange') ||
        n.contains('สตรอว์เบอร์รี') ||
        n.contains('strawberry') ||
        n.contains('องุ่น') ||
        n.contains('grape') ||
        n.contains('มะม่วง') ||
        n.contains('mango') ||
        n.contains('อะโวคาโด') ||
        n.contains('avocado') ||
        n.contains('สับปะรด') ||
        n.contains('pineapple') ||
        n.contains('แตงโม') ||
        n.contains('watermelon') ||
        n.contains('มะละกอ') ||
        n.contains('papaya') ||
        n.contains('ลิ้นจี่') ||
        n.contains('lychee') ||
        n.contains('ทุเรียน') ||
        n.contains('durian') ||
        n.contains('เงาะ') ||
        n.contains('rambutan') ||
        n.contains('ลำไย') ||
        n.contains('longan') ||
        n.contains('มะนาว') ||
        n.contains('lime') ||
        n.contains('lemon')) {
      return FoodCategory.fruit;
    }

    // Meat & Seafood
    if (n.contains('เนื้อ') ||
        n.contains('meat') ||
        n.contains('beef') ||
        n.contains('ไก่') ||
        n.contains('chicken') ||
        n.contains('หมู') ||
        n.contains('pork') ||
        n.contains('ปลา') ||
        n.contains('fish') ||
        n.contains('กุ้ง') ||
        n.contains('shrimp') ||
        n.contains('ปู') ||
        n.contains('crab') ||
        n.contains('หอย') ||
        n.contains('clam') ||
        n.contains('squid') ||
        n.contains('ปลาหมึก') ||
        n.contains('แฮม') ||
        n.contains('ham') ||
        n.contains('ไส้กรอก') ||
        n.contains('sausage') ||
        n.contains('เบคอน') ||
        n.contains('bacon')) {
      return FoodCategory.meat;
    }

    // Dairy
    if (n.contains('นม') ||
        n.contains('milk') ||
        n.contains('ไข่') ||
        n.contains('egg') ||
        n.contains('โยเกิร์ต') ||
        n.contains('yogurt') ||
        n.contains('เนย') ||
        n.contains('butter') ||
        n.contains('ชีส') ||
        n.contains('cheese') ||
        n.contains('ครีม') ||
        n.contains('cream')) {
      return FoodCategory.dairy;
    }

    // Beverages
    if (n.contains('น้ำ') ||
        n.contains('water') ||
        n.contains('juice') ||
        n.contains('น้ำผลไม้') ||
        n.contains('ชา') ||
        n.contains('tea') ||
        n.contains('กาแฟ') ||
        n.contains('coffee') ||
        n.contains('เครื่องดื่ม') ||
        n.contains('beverage') ||
        n.contains('drink') ||
        n.contains('โซดา') ||
        n.contains('soda') ||
        n.contains('น้ำอัดลม')) {
      return FoodCategory.beverage;
    }

    // Sauces & Condiments
    if (n.contains('ซอส') ||
        n.contains('sauce') ||
        n.contains('น้ำปลา') ||
        n.contains('fish sauce') ||
        n.contains('น้ำตาล') ||
        n.contains('sugar') ||
        n.contains('เกลือ') ||
        n.contains('salt') ||
        n.contains('พริก') ||
        n.contains('chili') ||
        n.contains('มายองเนส') ||
        n.contains('mayonnaise') ||
        n.contains('เครื่องปรุง') ||
        n.contains('condiment') ||
        n.contains('น้ำมัน') ||
        n.contains('oil') ||
        n.contains('น้ำส้มสายชู') ||
        n.contains('vinegar') ||
        n.contains('มัสตาร์ด') ||
        n.contains('mustard') ||
        n.contains('ketchup') ||
        n.contains('เคตชัป')) {
      return FoodCategory.sauce;
    }

    // Grains & Carbs
    if (n.contains('ข้าว') ||
        n.contains('rice') ||
        n.contains('ขนมปัง') ||
        n.contains('bread') ||
        n.contains('แป้ง') ||
        n.contains('flour') ||
        n.contains('เส้น') ||
        n.contains('noodle') ||
        n.contains('pasta') ||
        n.contains('พาสต้า') ||
        n.contains('ธัญพืช') ||
        n.contains('grain') ||
        n.contains('cereal') ||
        n.contains('ซีเรียล') ||
        n.contains('โอ๊ต') ||
        n.contains('oat') ||
        n.contains('ข้าวโอ๊ต')) {
      return FoodCategory.grain;
    }

    // Snacks
    if (n.contains('ขนม') ||
        n.contains('snack') ||
        n.contains('คุ้กกี้') ||
        n.contains('cookie') ||
        n.contains('เค้ก') ||
        n.contains('cake') ||
        n.contains('ช็อกโกแลต') ||
        n.contains('chocolate') ||
        n.contains('ลูกอม') ||
        n.contains('candy') ||
        n.contains('มันฝรั่ง') ||
        n.contains('chips') ||
        n.contains('popcorn') ||
        n.contains('ป็อปคอร์น') ||
        n.contains('ถั่ว') ||
        n.contains('nut') ||
        n.contains('biscuit') ||
        n.contains('บิสกิต')) {
      return FoodCategory.snack;
    }

    return FoodCategory.other;
  }

  String _emojiForFood(String name) {
    final n = name.toLowerCase();
    if (n.contains('นม') || n.contains('milk')) return '🥛';
    if (n.contains('ไข่') || n.contains('egg')) return '🥚';
    if (n.contains('ไก่') || n.contains('chicken')) return '🍗';
    if (n.contains('หมู') || n.contains('pork')) return '🥩';
    if (n.contains('เนื้อ') || n.contains('beef')) return '🥩';
    if (n.contains('ปลา') || n.contains('fish')) return '🐟';
    if (n.contains('กุ้ง') || n.contains('shrimp')) return '🦐';
    if (n.contains('ปู') || n.contains('crab')) return '🦀';
    if (n.contains('ปลาหมึก') || n.contains('squid')) return '🦑';
    if (n.contains('ผัก') || n.contains('veggie') || n.contains('vegetable')) return '🥦';
    if (n.contains('ผลไม้') || n.contains('fruit')) return '🍎';
    if (n.contains('แอปเปิ้ล') || n.contains('apple')) return '🍎';
    if (n.contains('กล้วย') || n.contains('banana')) return '🍌';
    if (n.contains('ส้ม') || n.contains('orange')) return '🍊';
    if (n.contains('มะเขือ') || n.contains('tomato')) return '🍅';
    if (n.contains('แครอท') || n.contains('carrot')) return '🥕';
    if (n.contains('ผักโขม') || n.contains('spinach')) return '🥬';
    if (n.contains('บร็อคโคลี') || n.contains('broccoli')) return '🥦';
    if (n.contains('กะหล่ำ') || n.contains('cabbage')) return '🥬';
    if (n.contains('แตงกวา') || n.contains('cucumber')) return '🥒';
    if (n.contains('ข้าวโพด') || n.contains('corn')) return '🌽';
    if (n.contains('โยเกิร์ต') || n.contains('yogurt')) return '🍶';
    if (n.contains('เนย') || n.contains('butter')) return '🧈';
    if (n.contains('ชีส') || n.contains('cheese')) return '🧀';
    if (n.contains('น้ำ') || n.contains('water') || n.contains('juice')) return '🧃';
    if (n.contains('ขนมปัง') || n.contains('bread')) return '🍞';
    if (n.contains('สตรอว์เบอร์รี') || n.contains('strawberry')) return '🍓';
    if (n.contains('องุ่น') || n.contains('grape')) return '🍇';
    if (n.contains('มะม่วง') || n.contains('mango')) return '🥭';
    if (n.contains('อะโวคาโด') || n.contains('avocado')) return '🥑';
    if (n.contains('เห็ด') || n.contains('mushroom')) return '🍄';
    if (n.contains('ข้าว') || n.contains('rice')) return '🍚';
    if (n.contains('ชา') || n.contains('tea')) return '🍵';
    if (n.contains('กาแฟ') || n.contains('coffee')) return '☕';
    if (n.contains('แฮม') || n.contains('ham')) return '🥓';
    if (n.contains('ไส้กรอก') || n.contains('sausage')) return '🌭';
    if (n.contains('เบคอน') || n.contains('bacon')) return '🥓';
    if (n.contains('ซอส') || n.contains('sauce')) return '🫙';
    if (n.contains('น้ำมัน') || n.contains('oil')) return '🫒';
    if (n.contains('แป้ง') || n.contains('flour')) return '🌾';
    if (n.contains('เส้น') || n.contains('noodle') || n.contains('pasta')) return '🍜';
    if (n.contains('ขนม') || n.contains('snack')) return '🍿';
    if (n.contains('ช็อกโกแลต') || n.contains('chocolate')) return '🍫';
    if (n.contains('เค้ก') || n.contains('cake')) return '🎂';
    if (n.contains('ถั่ว') || n.contains('nut')) return '🥜';
    if (n.contains('มะนาว') || n.contains('lime') || n.contains('lemon')) return '🍋';
    if (n.contains('สับปะรด') || n.contains('pineapple')) return '🍍';
    if (n.contains('แตงโม') || n.contains('watermelon')) return '🍉';
    if (n.contains('มะละกอ') || n.contains('papaya')) return '🍈';
    if (n.contains('ทุเรียน') || n.contains('durian')) return '🍈';
    if (n.contains('ลำไย') || n.contains('longan')) return '🍑';
    if (n.contains('หัวหอม') || n.contains('onion')) return '🧅';
    if (n.contains('กระเทียม') || n.contains('garlic')) return '🧄';
    return '🍽️';
  }
}

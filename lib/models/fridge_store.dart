import 'package:flutter/foundation.dart';
import 'food_item.dart';
import 'scan_result.dart';

/// Simple in-memory store — single source of truth for fridge items.
class FridgeStore extends ChangeNotifier {
  FridgeStore._();
  static final FridgeStore instance = FridgeStore._();

  final List<FoodItem> _items = [...sampleItems];

  List<FoodItem> get items => List.unmodifiable(_items);

  /// Convert [DetectedFoodItem]s from a scan and add them to the fridge.
  void addFromScan(List<DetectedFoodItem> detected) {
    var idCounter = DateTime.now().millisecondsSinceEpoch;
    for (final d in detected) {
      final expiry = d.estimatedExpiry ??
          DateTime.now().add(const Duration(days: 7)); // fallback: 1 week
      final daysLeft = expiry.difference(DateTime.now()).inDays.clamp(0, 365);
      final score = _freshnessScore(daysLeft);

      _items.add(FoodItem(
        id: '${idCounter++}',
        name: d.name,
        emoji: _emojiForFood(d.name),
        expiryDate: expiry,
        freshnessScore: score,
      ));
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  void clearAll() {
    _items.clear();
    notifyListeners();
  }

  // ── helpers ─────────────────────────────────────────────────

  int _freshnessScore(int daysLeft) {
    if (daysLeft > 14) return 92;
    if (daysLeft > 7) return 75;
    if (daysLeft > 3) return 55;
    if (daysLeft > 1) return 30;
    return 10;
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
    return '🍽️';
  }
}

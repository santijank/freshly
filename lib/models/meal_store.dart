import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'meal_log.dart';
import 'user_profile.dart';

class MealStore extends ChangeNotifier {
  MealStore._();
  static final MealStore instance = MealStore._();

  static const _kMealsKey = 'nourish_meals_v1';
  static const _kProfileKey = 'nourish_profile_v1';

  final List<MealLog> _meals = [];
  UserProfile? _profile;

  UserProfile? get profile => _profile;
  bool get hasProfile => _profile != null;
  List<MealLog> get allMeals => List.unmodifiable(_meals);

  List<MealLog> getMealsForDate(DateTime date) => _meals
      .where((m) =>
          m.date.year == date.year &&
          m.date.month == date.month &&
          m.date.day == date.day)
      .toList();

  List<MealLog> get todayMeals => getMealsForDate(DateTime.now());

  FoodNutrition get todayNutrition =>
      todayMeals.fold(FoodNutrition.zero, (sum, meal) => sum + meal.totalNutrition);

  Map<DateTime, FoodNutrition> get weeklyNutrition {
    final map = <DateTime, FoodNutrition>{};
    for (int i = 6; i >= 0; i--) {
      final day = DateTime.now().subtract(Duration(days: i));
      final dayKey = DateTime(day.year, day.month, day.day);
      map[dayKey] = getMealsForDate(day)
          .fold(FoodNutrition.zero, (sum, m) => sum + m.totalNutrition);
    }
    return map;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final profileJson = prefs.getString(_kProfileKey);
    if (profileJson != null) {
      _profile = UserProfile.fromJson(
          jsonDecode(profileJson) as Map<String, dynamic>);
    }

    final rawMeals = prefs.getStringList(_kMealsKey) ?? [];
    _meals.addAll(rawMeals.map(
        (s) => MealLog.fromJson(jsonDecode(s) as Map<String, dynamic>)));

    notifyListeners();
  }

  Future<void> saveProfile(UserProfile profile) async {
    _profile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfileKey, jsonEncode(profile.toJson()));
    notifyListeners();
  }

  Future<void> addMeal(MealLog meal) async {
    _meals.add(meal);
    await _saveMeals();
    notifyListeners();
  }

  Future<void> deleteMeal(String id) async {
    _meals.removeWhere((m) => m.id == id);
    await _saveMeals();
    notifyListeners();
  }

  Future<void> _saveMeals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _kMealsKey, _meals.map((m) => jsonEncode(m.toJson())).toList());
  }

  /// Returns how many consecutive days (including today) the user has logged meals
  int get streakDays {
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      if (getMealsForDate(day).isNotEmpty) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}

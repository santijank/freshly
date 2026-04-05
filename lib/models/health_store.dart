import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'health_metrics.dart';

class HealthStore extends ChangeNotifier {
  HealthStore._();
  static final HealthStore instance = HealthStore._();

  static const _kReportsKey = 'nourish_lab_reports_v1';

  final List<LabReport> _reports = [];

  List<LabReport> get reports {
    final sorted = List<LabReport>.from(_reports);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(sorted);
  }

  LabReport? get latestReport => reports.isEmpty ? null : reports.first;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_kReportsKey) ?? [];
    _reports.clear();
    for (final s in rawList) {
      try {
        final decoded = jsonDecode(s) as Map<String, dynamic>;
        _reports.add(LabReport.fromJson(decoded));
      } catch (_) {
        // skip corrupted entry
      }
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kReportsKey,
      _reports.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  Future<void> addReport(LabReport report) async {
    _reports.add(report);
    await _save();
    notifyListeners();
  }

  Future<void> deleteReport(String id) async {
    _reports.removeWhere((r) => r.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> updateDietaryPlan(String id, String plan) async {
    final index = _reports.indexWhere((r) => r.id == id);
    if (index == -1) return;
    _reports[index] = _reports[index].copyWith(dietaryPlan: plan);
    await _save();
    notifyListeners();
  }
}

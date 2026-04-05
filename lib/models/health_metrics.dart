import 'package:flutter/material.dart';

enum MetricStatus { normal, borderline, high, low }

enum MetricCategory {
  bloodSugar,
  lipid,
  bloodCount,
  liver,
  kidney,
  thyroid,
  other,
}

class HealthMetric {
  final String name;
  final String nameThai;
  final double value;
  final String unit;
  final double? normalMin;
  final double? normalMax;
  final MetricStatus status;
  final MetricCategory category;

  const HealthMetric({
    required this.name,
    required this.nameThai,
    required this.value,
    required this.unit,
    this.normalMin,
    this.normalMax,
    required this.status,
    required this.category,
  });

  Color get statusColor {
    switch (status) {
      case MetricStatus.normal:
        return const Color(0xFF2E7D32); // AppColors.good
      case MetricStatus.borderline:
        return const Color(0xFFFF6F00); // AppColors.warning
      case MetricStatus.high:
        return const Color(0xFFD32F2F); // AppColors.danger
      case MetricStatus.low:
        return const Color(0xFFD32F2F); // AppColors.danger
    }
  }

  String get statusLabel {
    switch (status) {
      case MetricStatus.normal:
        return 'ปกติ';
      case MetricStatus.borderline:
        return 'เกือบสูง';
      case MetricStatus.high:
        return 'สูง';
      case MetricStatus.low:
        return 'ต่ำ';
    }
  }

  String get categoryLabel {
    switch (category) {
      case MetricCategory.bloodSugar:
        return 'น้ำตาลในเลือด';
      case MetricCategory.lipid:
        return 'ไขมันในเลือด';
      case MetricCategory.bloodCount:
        return 'ความสมบูรณ์เลือด';
      case MetricCategory.liver:
        return 'ตับ';
      case MetricCategory.kidney:
        return 'ไต';
      case MetricCategory.thyroid:
        return 'ไทรอยด์';
      case MetricCategory.other:
        return 'อื่นๆ';
    }
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'name_thai': nameThai,
        'value': value,
        'unit': unit,
        'normal_min': normalMin,
        'normal_max': normalMax,
        'status': status.name,
        'category': category.name,
      };

  factory HealthMetric.fromJson(Map<String, dynamic> json) {
    MetricStatus status;
    switch (json['status'] as String? ?? 'normal') {
      case 'high':
        status = MetricStatus.high;
        break;
      case 'low':
        status = MetricStatus.low;
        break;
      case 'borderline':
        status = MetricStatus.borderline;
        break;
      default:
        status = MetricStatus.normal;
    }

    MetricCategory category;
    switch (json['category'] as String? ?? 'other') {
      case 'bloodSugar':
        category = MetricCategory.bloodSugar;
        break;
      case 'lipid':
        category = MetricCategory.lipid;
        break;
      case 'bloodCount':
        category = MetricCategory.bloodCount;
        break;
      case 'liver':
        category = MetricCategory.liver;
        break;
      case 'kidney':
        category = MetricCategory.kidney;
        break;
      case 'thyroid':
        category = MetricCategory.thyroid;
        break;
      default:
        category = MetricCategory.other;
    }

    return HealthMetric(
      name: json['name'] as String? ?? '',
      nameThai: json['name_thai'] as String? ?? json['name'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
      normalMin: (json['normal_min'] as num?)?.toDouble(),
      normalMax: (json['normal_max'] as num?)?.toDouble(),
      status: status,
      category: category,
    );
  }
}

class LabReport {
  final String id;
  final DateTime date;
  final String? imagePath;
  final List<HealthMetric> metrics;
  final String? dietaryPlan;
  final String? labName;

  const LabReport({
    required this.id,
    required this.date,
    this.imagePath,
    required this.metrics,
    this.dietaryPlan,
    this.labName,
  });

  List<HealthMetric> get abnormalMetrics =>
      metrics.where((m) => m.status != MetricStatus.normal).toList();

  bool get hasAbnormal => abnormalMetrics.isNotEmpty;

  LabReport copyWith({
    String? id,
    DateTime? date,
    String? imagePath,
    List<HealthMetric>? metrics,
    String? dietaryPlan,
    String? labName,
  }) {
    return LabReport(
      id: id ?? this.id,
      date: date ?? this.date,
      imagePath: imagePath ?? this.imagePath,
      metrics: metrics ?? this.metrics,
      dietaryPlan: dietaryPlan ?? this.dietaryPlan,
      labName: labName ?? this.labName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'imagePath': imagePath,
        'metrics': metrics.map((m) => m.toJson()).toList(),
        'dietaryPlan': dietaryPlan,
        'labName': labName,
      };

  factory LabReport.fromJson(Map<String, dynamic> json) {
    final rawMetrics = json['metrics'] as List?;
    return LabReport(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      imagePath: json['imagePath'] as String?,
      metrics: rawMetrics
              ?.whereType<Map<String, dynamic>>()
              .map(HealthMetric.fromJson)
              .toList() ??
          [],
      dietaryPlan: json['dietaryPlan'] as String?,
      labName: json['labName'] as String?,
    );
  }
}

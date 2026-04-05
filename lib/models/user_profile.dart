enum HealthGoal { loseWeight, gainMuscle, maintain, eatHealthier }

class UserProfile {
  String name;
  int age;
  double weightKg;
  double heightCm;
  String gender; // 'male' or 'female'
  HealthGoal goal;
  int dailyCalorieTarget;
  int dailyProteinTarget;
  int dailyCarbTarget;
  int dailyFatTarget;

  UserProfile({
    required this.name,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.gender,
    required this.goal,
    required this.dailyCalorieTarget,
    required this.dailyProteinTarget,
    required this.dailyCarbTarget,
    required this.dailyFatTarget,
  });

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  String get bmiLabel {
    final b = bmi;
    if (b < 18.5) return 'น้ำหนักน้อย';
    if (b < 25) return 'ปกติ';
    if (b < 30) return 'น้ำหนักเกิน';
    return 'อ้วน';
  }

  String get goalLabel {
    switch (goal) {
      case HealthGoal.loseWeight:
        return 'ลดน้ำหนัก';
      case HealthGoal.gainMuscle:
        return 'เพิ่มกล้ามเนื้อ';
      case HealthGoal.maintain:
        return 'รักษาน้ำหนัก';
      case HealthGoal.eatHealthier:
        return 'กินอาหารดีขึ้น';
    }
  }

  static UserProfile create({
    required String name,
    required int age,
    required double weightKg,
    required double heightCm,
    required String gender,
    required HealthGoal goal,
  }) {
    double bmr = gender == 'male'
        ? (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5
        : (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;

    int tdee = (bmr * 1.4).round();

    int calories = switch (goal) {
      HealthGoal.loseWeight => tdee - 500,
      HealthGoal.gainMuscle => tdee + 300,
      _ => tdee,
    };

    // Ensure minimum sensible calories
    if (calories < 1200) calories = 1200;

    int protein = ((calories * 0.30) / 4).round();
    int carbs = ((calories * 0.40) / 4).round();
    int fat = ((calories * 0.30) / 9).round();

    return UserProfile(
      name: name,
      age: age,
      weightKg: weightKg,
      heightCm: heightCm,
      gender: gender,
      goal: goal,
      dailyCalorieTarget: calories,
      dailyProteinTarget: protein,
      dailyCarbTarget: carbs,
      dailyFatTarget: fat,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'gender': gender,
        'goal': goal.index,
        'dailyCalorieTarget': dailyCalorieTarget,
        'dailyProteinTarget': dailyProteinTarget,
        'dailyCarbTarget': dailyCarbTarget,
        'dailyFatTarget': dailyFatTarget,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] as String,
        age: json['age'] as int,
        weightKg: (json['weightKg'] as num).toDouble(),
        heightCm: (json['heightCm'] as num).toDouble(),
        gender: json['gender'] as String,
        goal: HealthGoal.values[json['goal'] as int],
        dailyCalorieTarget: json['dailyCalorieTarget'] as int,
        dailyProteinTarget: json['dailyProteinTarget'] as int,
        dailyCarbTarget: json['dailyCarbTarget'] as int,
        dailyFatTarget: json['dailyFatTarget'] as int,
      );
}

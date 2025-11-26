import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  final String userId;
  final String? name;
  final double? weight; // kg
  final double? height; // cm
  final int? age;
  final String? gender; // 'male', 'female', 'other'
  final double? targetWeight;
  final String? activityLevel;
  final List<String>? restrictions;
  final List<String>? preferences;
  final double? dailyCalories;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProfileEntity({
    required this.userId,
    this.name,
    this.weight,
    this.height,
    this.age,
    this.gender,
    this.targetWeight,
    this.activityLevel,
    this.restrictions,
    this.preferences,
    this.dailyCalories,
    this.createdAt,
    this.updatedAt,
  });

  double? get bmi {
    if (weight == null || height == null) return null;
    return weight! / ((height! / 100) * (height! / 100));
  }

  @override
  List<Object?> get props => [
    userId,
    name,
    weight,
    height,
    age,
    gender,
    targetWeight,
    activityLevel,
    restrictions,
    preferences,
    dailyCalories,
    createdAt,
    updatedAt,
  ];
}

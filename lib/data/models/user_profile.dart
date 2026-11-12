import 'dart:convert';

class UserProfile {
  final int id;
  final String name;
  final Map<String, double> nutritionTargets;
  final List<String> allergens;
  final String updatedAt;

  UserProfile({
    this.id = 1,
    required this.name,
    this.nutritionTargets = const {},
    this.allergens = const [],
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nutrition_targets': jsonEncode(nutritionTargets),
      'updated_at': updatedAt,
    };
  }

  factory UserProfile.fromMap(
    Map<String, dynamic> map, {
    List<String> allergens = const [],
  }) {
    Map<String, double> parsedTargets = {};
    if (map['nutrition_targets'] != null &&
        (map['nutrition_targets'] as String).isNotEmpty) {
      final decoded = jsonDecode(map['nutrition_targets'] as String)
          as Map<String, dynamic>;
      parsedTargets = decoded.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    }

    return UserProfile(
      id: map['id'] as int? ?? 1,
      name: map['name'] as String? ?? '',
      nutritionTargets: parsedTargets,
      allergens: allergens,
      updatedAt:
          map['updated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}

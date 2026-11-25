import 'dart:convert';

class UserProfile {
  final int id;
  final int? userId;
  final bool isGuest;
  final String name;
  final Map<String, double> nutritionTargets;
  final List<String> allergens;
  final String updatedAt;

  UserProfile({
    this.id = 1,
    this.userId,
    this.isGuest = false,
    required this.name,
    this.nutritionTargets = const {},
    this.allergens = const [],
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id > 0) 'id': id,
      'user_id': userId,
      'is_guest': isGuest ? 1 : 0,
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
      userId: map['user_id'] as int?,
      isGuest: (map['is_guest'] as int? ?? 0) == 1 || map['user_id'] == null,
      name: map['name'] as String? ?? '',
      nutritionTargets: parsedTargets,
      allergens: allergens,
      updatedAt:
          map['updated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}

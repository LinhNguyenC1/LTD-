class UserAllergen {
  final int? id;
  final int profileId;
  final String allergenCode;

  UserAllergen({
    this.id,
    this.profileId = 1,
    required this.allergenCode,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'profile_id': profileId,
      'allergen_code': allergenCode,
    };
  }

  factory UserAllergen.fromMap(Map<String, dynamic> map) {
    return UserAllergen(
      id: map['id'] as int?,
      profileId: map['profile_id'] as int? ?? 1,
      allergenCode: map['allergen_code'] as String,
    );
  }
}

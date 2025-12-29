enum CattleStatus { active, sold }
enum CattleGender { male, female }
enum AgeCategory { calf, young, adult }

/// Central Cattle Registry - Master Record (Identity Only)
/// Contains only static identification data, no events or costs
class CattleRegistry {
  final int? id;
  final String earTag;           // Unique identifier (mandatory)
  final CattleGender gender;     // Male/Female
  final AgeCategory ageCategory; // Calf/Young/Adult
  final DateTime registrationDate; // When registered in system
  final CattleStatus status;     // Active/Sold

  CattleRegistry({
    this.id,
    required this.earTag,
    required this.gender,
    required this.ageCategory,
    required this.registrationDate,
    this.status = CattleStatus.active,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'earTag': earTag,
      'gender': gender.name,
      'ageCategory': ageCategory.name,
      'registrationDate': registrationDate.toIso8601String(),
      'status': status.name,
    };
  }

  factory CattleRegistry.fromMap(Map<String, dynamic> map) {
    return CattleRegistry(
      id: map['id'] as int?,
      earTag: map['earTag'] as String? ?? '',
      gender: CattleGender.values.firstWhere(
        (e) => e.name == map['gender'],
        orElse: () => CattleGender.male,
      ),
      ageCategory: AgeCategory.values.firstWhere(
        (e) => e.name == map['ageCategory'],
        orElse: () => AgeCategory.adult,
      ),
      registrationDate: map['registrationDate'] != null ? DateTime.parse(map['registrationDate'] as String) : DateTime.now(),
      status: CattleStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CattleStatus.active,
      ),
    );
  }

  CattleRegistry copyWith({
    int? id,
    String? earTag,
    CattleGender? gender,
    AgeCategory? ageCategory,
    DateTime? registrationDate,
    CattleStatus? status,
  }) {
    return CattleRegistry(
      id: id ?? this.id,
      earTag: earTag ?? this.earTag,
      gender: gender ?? this.gender,
      ageCategory: ageCategory ?? this.ageCategory,
      registrationDate: registrationDate ?? this.registrationDate,
      status: status ?? this.status,
    );
  }

  /// Age category display name in Tajik
  String get ageCategoryDisplay {
    switch (ageCategory) {
      case AgeCategory.calf: return 'Гӯсола';
      case AgeCategory.young: return 'Ҷавон';
      case AgeCategory.adult: return 'Калонсол';
    }
  }

  /// Gender display name in Tajik
  String get genderDisplay {
    switch (gender) {
      case CattleGender.male: return 'Нар';
      case CattleGender.female: return 'Мода';
    }
  }

  /// Status display name in Tajik
  String get statusDisplay {
    switch (status) {
      case CattleStatus.active: return 'Фаъол';
      case CattleStatus.sold: return 'Фурӯхта шуда';
    }
  }

  /// Validates cattle registry data
  static String? validate({required String earTag}) {
    if (earTag.trim().isEmpty) return 'Рамзи гӯш зарур аст';
    return null;
  }
}

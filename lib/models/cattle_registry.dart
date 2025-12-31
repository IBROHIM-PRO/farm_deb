enum CattleStatus { active, sold }
enum CattleGender { male, female }
enum AgeCategory { calf, young, adult }

/// Central Cattle Registry - Master Record (Identity Only)
/// Contains only static identification data, no events or costs
class CattleRegistry {
  final int? id;
  final String earTag;           // Unique identifier (mandatory)
  final String? name;            // Optional name for cattle
  final CattleGender gender;     // Male/Female
  final AgeCategory ageCategory; // Calf/Young/Adult
  final int? barnId;             // Barn where cattle is housed
  final int? breederId;          // Breeder/Seller person
  final DateTime registrationDate; // When registered in system
  final CattleStatus status;     // Active/Sold

  CattleRegistry({
    this.id,
    required this.earTag,
    this.name,
    required this.gender,
    required this.ageCategory,
    this.barnId,
    this.breederId,
    required this.registrationDate,
    this.status = CattleStatus.active,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'earTag': earTag,
      'name': name,
      'gender': gender.name,
      'ageCategory': ageCategory.name,
      'barnId': barnId,
      'breederId': breederId,
      'registrationDate': registrationDate.toIso8601String(),
      'status': status.name,
    };
  }

  factory CattleRegistry.fromMap(Map<String, dynamic> map) {
    return CattleRegistry(
      id: map['id'] as int?,
      earTag: map['earTag'] as String? ?? '',
      name: map['name'] as String?,
      gender: CattleGender.values.firstWhere(
        (e) => e.name == map['gender'],
        orElse: () => CattleGender.male,
      ),
      ageCategory: AgeCategory.values.firstWhere(
        (e) => e.name == map['ageCategory'],
        orElse: () => AgeCategory.adult,
      ),
      barnId: map['barnId'] as int?,
      breederId: map['breederId'] as int?,
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
    String? name,
    CattleGender? gender,
    AgeCategory? ageCategory,
    int? barnId,
    int? breederId,
    DateTime? registrationDate,
    CattleStatus? status,
  }) {
    return CattleRegistry(
      id: id ?? this.id,
      earTag: earTag ?? this.earTag,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      ageCategory: ageCategory ?? this.ageCategory,
      barnId: barnId ?? this.barnId,
      breederId: breederId ?? this.breederId,
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

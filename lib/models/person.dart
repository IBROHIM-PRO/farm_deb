/// Person Entity - Represents a person involved in a transaction
/// Exactly as specified in theoretical design
class Person {
  final int? id;
  final String fullName;
  final String? phone;

  Person({
    this.id,
    required this.fullName,
    this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
    };
  }

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      id: map['id'] as int?,
      fullName: map['fullName'] as String? ?? '',
      phone: map['phone'] as String?,
    );
  }

  Person copyWith({
    int? id,
    String? fullName,
    String? phone,
  }) {
    return Person(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
    );
  }

  /// Validation for Person entity
  static String? validate(String fullName) {
    if (fullName.trim().isEmpty) {
      return 'Номи пурра зарур аст';
    }
    return null;
  }
}

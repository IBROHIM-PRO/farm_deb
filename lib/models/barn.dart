/// Barn Model - Livestock housing location
/// Manages barn details and capacity for organizing cattle
class Barn {
  final int? id;
  final String name;              // Barn name/identifier
  final String? location;         // Physical location description
  final int? capacity;            // Maximum number of cattle
  final DateTime createdDate;
  final String? notes;

  Barn({
    this.id,
    required this.name,
    this.location,
    this.capacity,
    DateTime? createdDate,
    this.notes,
  }) : createdDate = createdDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'capacity': capacity,
      'createdDate': createdDate.toIso8601String(),
      'notes': notes,
    };
  }

  factory Barn.fromMap(Map<String, dynamic> map) {
    return Barn(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      location: map['location'] as String?,
      capacity: map['capacity'] as int?,
      createdDate: map['createdDate'] != null 
          ? DateTime.parse(map['createdDate'] as String) 
          : DateTime.now(),
      notes: map['notes'] as String?,
    );
  }

  Barn copyWith({
    int? id,
    String? name,
    String? location,
    int? capacity,
    DateTime? createdDate,
    String? notes,
  }) {
    return Barn(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      capacity: capacity ?? this.capacity,
      createdDate: createdDate ?? this.createdDate,
      notes: notes ?? this.notes,
    );
  }

  /// Validates barn data
  static String? validate({required String name}) {
    if (name.trim().isEmpty) return 'Номи оғул зарур аст';
    return null;
  }
}

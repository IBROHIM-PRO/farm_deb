class Buyer {
  final int? id;
  final String name;
  final String? phone;
  final String? notes;

  Buyer({
    this.id,
    required this.name,
    this.phone,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'notes': notes,
    };
  }

  static Buyer fromMap(Map<String, dynamic> map) {
    return Buyer(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      phone: map['phone'],
      notes: map['notes'],
    );
  }

  Buyer copyWith({
    int? id,
    String? name,
    String? phone,
    String? notes,
  }) {
    return Buyer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
    );
  }
}

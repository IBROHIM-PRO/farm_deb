class CottonProcessing {
  final int? id;
  final DateTime processingDate;
  final double? lintWeight;
  final double? ulukWeight;
  final double? valaknoWeight;
  final double? extraValaknoWeight;
  final int? lintUnits;
  final int? ulukUnits;
  final int? valaknoUnits;
  final int? extraValaknoUnits;
  final double totalInputWeight;
  final double processedOutputWeight;
  final int processedUnits;
  final double yieldPercentage;

  CottonProcessing({
    this.id,
    required this.processingDate,
    this.lintWeight,
    this.ulukWeight,
    this.valaknoWeight,
    this.extraValaknoWeight,
    this.lintUnits,
    this.ulukUnits,
    this.valaknoUnits,
    this.extraValaknoUnits,
    required this.totalInputWeight,
    required this.processedOutputWeight,
    required this.processedUnits,
    required this.yieldPercentage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'processingDate': processingDate.toIso8601String(),
      'lintWeight': lintWeight,
      'ulukWeight': ulukWeight,
      'valaknoWeight': valaknoWeight,
      'extraValaknoWeight': extraValaknoWeight,
      'lintUnits': lintUnits,
      'ulukUnits': ulukUnits,
      'valaknoUnits': valaknoUnits,
      'extraValaknoUnits': extraValaknoUnits,
      'totalInputWeight': totalInputWeight,
      'processedOutputWeight': processedOutputWeight,
      'processedUnits': processedUnits,
      'yieldPercentage': yieldPercentage,
    };
  }

  static CottonProcessing fromMap(Map<String, dynamic> map) {
    return CottonProcessing(
      id: map['id']?.toInt(),
      processingDate: DateTime.parse(map['processingDate'] ?? DateTime.now().toIso8601String()),
      lintWeight: map['lintWeight']?.toDouble(),
      ulukWeight: map['ulukWeight']?.toDouble(),
      valaknoWeight: map['valaknoWeight']?.toDouble(),
      extraValaknoWeight: map['extraValaknoWeight']?.toDouble(),
      lintUnits: map['lintUnits']?.toInt(),
      ulukUnits: map['ulukUnits']?.toInt(),
      valaknoUnits: map['valaknoUnits']?.toInt(),
      extraValaknoUnits: map['extraValaknoUnits']?.toInt(),
      totalInputWeight: map['totalInputWeight']?.toDouble() ?? 0.0,
      processedOutputWeight: map['processedOutputWeight']?.toDouble() ?? 0.0,
      processedUnits: map['processedUnits']?.toInt() ?? 0,
      yieldPercentage: map['yieldPercentage']?.toDouble() ?? 0.0,
    );
  }

  CottonProcessing copyWith({
    int? id,
    DateTime? processingDate,
    double? lintWeight,
    double? ulukWeight,
    double? valaknoWeight,
    double? extraValaknoWeight,
    int? lintUnits,
    int? ulukUnits,
    int? valaknoUnits,
    int? extraValaknoUnits,
    double? totalInputWeight,
    double? processedOutputWeight,
    int? processedUnits,
    double? yieldPercentage,
  }) {
    return CottonProcessing(
      id: id ?? this.id,
      processingDate: processingDate ?? this.processingDate,
      lintWeight: lintWeight ?? this.lintWeight,
      ulukWeight: ulukWeight ?? this.ulukWeight,
      valaknoWeight: valaknoWeight ?? this.valaknoWeight,
      extraValaknoWeight: extraValaknoWeight ?? this.extraValaknoWeight,
      lintUnits: lintUnits ?? this.lintUnits,
      ulukUnits: ulukUnits ?? this.ulukUnits,
      valaknoUnits: valaknoUnits ?? this.valaknoUnits,
      extraValaknoUnits: extraValaknoUnits ?? this.extraValaknoUnits,
      totalInputWeight: totalInputWeight ?? this.totalInputWeight,
      processedOutputWeight: processedOutputWeight ?? this.processedOutputWeight,
      processedUnits: processedUnits ?? this.processedUnits,
      yieldPercentage: yieldPercentage ?? this.yieldPercentage,
    );
  }

  bool get hasLint => lintWeight != null && lintWeight! > 0;
  bool get hasUluk => ulukWeight != null && ulukWeight! > 0;
  bool get hasValakno => valaknoWeight != null && valaknoWeight! > 0;
  bool get hasExtraValakno => extraValaknoWeight != null && extraValaknoWeight! > 0;

  List<String> get cottonTypes {
    List<String> types = [];
    if (hasLint) types.add('Lint');
    if (hasUluk) types.add('Uluk');
    if (hasValakno) types.add('Valakno');
    return types;
  }
}

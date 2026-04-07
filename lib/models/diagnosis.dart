class Diagnosis {
  final int? id;
  final String imagePath;
  final String disease;
  final double confidence;
  final double? latitude;
  final double? longitude;
  final DateTime timestamp;
  final String notes;

  const Diagnosis({
    this.id,
    required this.imagePath,
    required this.disease,
    required this.confidence,
    this.latitude,
    this.longitude,
    required this.timestamp,
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'imagePath': imagePath,
        'disease': disease,
        'confidence': confidence,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
        'notes': notes,
      };

  factory Diagnosis.fromMap(Map<String, dynamic> map) => Diagnosis(
        id: map['id'] as int?,
        imagePath: map['imagePath'] as String,
        disease: map['disease'] as String,
        confidence: (map['confidence'] as num).toDouble(),
        latitude: map['latitude'] != null
            ? (map['latitude'] as num).toDouble()
            : null,
        longitude: map['longitude'] != null
            ? (map['longitude'] as num).toDouble()
            : null,
        timestamp: DateTime.parse(map['timestamp'] as String),
        notes: map['notes'] as String? ?? '',
      );

  Diagnosis copyWith({
    int? id,
    String? imagePath,
    String? disease,
    double? confidence,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    String? notes,
  }) =>
      Diagnosis(
        id: id ?? this.id,
        imagePath: imagePath ?? this.imagePath,
        disease: disease ?? this.disease,
        confidence: confidence ?? this.confidence,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        timestamp: timestamp ?? this.timestamp,
        notes: notes ?? this.notes,
      );
}

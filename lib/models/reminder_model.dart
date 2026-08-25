class ReminderModel {
  final String id;
  final String petId;
  final String title;
  final String type; // 'vacina' | 'banho' | 'consulta' | 'remedio' | 'outro'
  final DateTime dateTime;
  final String? notes;
  final bool isDone;

  ReminderModel({
    required this.id,
    required this.petId,
    required this.title,
    required this.type,
    required this.dateTime,
    this.notes,
    this.isDone = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'petId': petId,
        'title': title,
        'type': type,
        'dateTime': dateTime.toIso8601String(),
        'notes': notes,
        'isDone': isDone,
      };

  static ReminderModel fromJson(Map<String, dynamic> json) => ReminderModel(
        id: json['id'] ?? '',
        petId: json['petId'] ?? '',
        title: json['title'] ?? '',
        type: json['type'] ?? 'outro',
        dateTime: DateTime.parse(json['dateTime']),
        notes: json['notes'],
        isDone: json['isDone'] ?? false,
      );

  ReminderModel copyWith({
    String? id,
    String? petId,
    String? title,
    String? type,
    DateTime? dateTime,
    String? notes,
    bool? isDone,
  }) =>
      ReminderModel(
        id: id ?? this.id,
        petId: petId ?? this.petId,
        title: title ?? this.title,
        type: type ?? this.type,
        dateTime: dateTime ?? this.dateTime,
        notes: notes ?? this.notes,
        isDone: isDone ?? this.isDone,
      );
}

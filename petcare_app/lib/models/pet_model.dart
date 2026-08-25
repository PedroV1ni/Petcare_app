class PetModel {
  final String id;
  final String name;
  final String description;
  final DateTime birthDate;
  final String breed;
  final String species; // 'dog' | 'cat' | 'other'
  final String size;
  final double weight;
  final String imageUrl; // path local OU 'assets/...'

  PetModel({
    required this.id,
    required this.name,
    required this.description,
    required this.birthDate,
    required this.breed,
    this.species = 'dog',
    required this.size,
    required this.weight,
    required this.imageUrl,
  });

  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Retorna true se a imagem vem dos assets do app
  bool get isAssetImage => imageUrl.startsWith('assets/');

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'birthDate': birthDate.toIso8601String(),
        'breed': breed,
        'species': species,
        'size': size,
        'weight': weight,
        'imageUrl': imageUrl,
      };

  static PetModel fromJson(Map<String, dynamic> json) => PetModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        birthDate: DateTime.parse(json['birthDate']),
        breed: json['breed'] ?? '',
        species: json['species'] ?? 'dog',
        size: json['size'] ?? '',
        weight: (json['weight'] as num).toDouble(),
        imageUrl: json['imageUrl'] ?? '',
      );

  PetModel copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? birthDate,
    String? breed,
    String? species,
    String? size,
    double? weight,
    String? imageUrl,
  }) =>
      PetModel(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        birthDate: birthDate ?? this.birthDate,
        breed: breed ?? this.breed,
        species: species ?? this.species,
        size: size ?? this.size,
        weight: weight ?? this.weight,
        imageUrl: imageUrl ?? this.imageUrl,
      );
}

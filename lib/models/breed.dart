class Breed {
  final String name;
  final String species; // 'dog' | 'cat'
  final String image;
  final String origin;
  final String size;
  final List<String> temperament;
  final String description;
  final List<String> tips;
  final List<String> curiosities;

  Breed({
    required this.name,
    required this.species,
    required this.image,
    required this.origin,
    required this.size,
    required this.temperament,
    required this.description,
    required this.tips,
    required this.curiosities,
  });

  factory Breed.fromJson(Map<String, dynamic> json) => Breed(
        name: json['name'] ?? '',
        species: json['species'] ?? 'dog',
        image: json['image'] ?? '',
        origin: json['origin'] ?? '',
        size: json['size'] ?? '',
        temperament: List<String>.from(json['temperament'] ?? []),
        description: json['description'] ?? '',
        tips: List<String>.from(json['tips'] ?? []),
        curiosities: List<String>.from(json['curiosities'] ?? []),
      );
}

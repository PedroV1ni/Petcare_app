class TipModel {
  final int id;
  final String title;
  final String image;
  final String category;
  final String summary;
  final String content;

  TipModel({
    required this.id,
    required this.title,
    required this.image,
    required this.category,
    required this.summary,
    required this.content,
  });

  factory TipModel.fromJson(Map<String, dynamic> json) {
    return TipModel(
      id: json['id'],
      title: json['title'],
      image: json['image'],
      category: json['category'],
      summary: json['summary'],
      content: json['content'],
    );
  }
}

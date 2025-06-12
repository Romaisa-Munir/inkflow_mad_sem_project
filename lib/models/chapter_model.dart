class Chapter {
  final String id;
  final String title;
  final String content;
  final double price;
  final int createdAt;
  final int? updatedAt;

  Chapter({
    required this.id,
    required this.title,
    required this.content,
    required this.price,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert Chapter to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'price': price,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create Chapter from Firebase Map
  static Chapter fromMap(Map<String, dynamic> map, String id) {
    return Chapter(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      createdAt: map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: map['updatedAt'],
    );
  }

  // Create a copy with updated fields
  Chapter copyWith({
    String? id,
    String? title,
    String? content,
    double? price,
    int? createdAt,
    int? updatedAt,
  }) {
    return Chapter(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
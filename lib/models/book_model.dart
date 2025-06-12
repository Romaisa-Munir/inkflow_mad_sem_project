class Book {
  final String id;
  final String title;
  final String description;
  final String? coverImage; // base64 string
  final String authorId;
  final int createdAt;
  final String status;
  final int likesCount; // Add likes count for each book

  Book({
    required this.id,
    required this.title,
    required this.description,
    this.coverImage,
    required this.authorId,
    required this.createdAt,
    this.status = 'draft',
    this.likesCount = 0, // Default to 0 likes
  });

  // Factory constructor to create Book from map
  factory Book.fromMap(String id, Map<String, dynamic> data) {
    return Book(
      id: id,
      title: data['title'] ?? 'Untitled',
      description: data['description'] ?? 'No description',
      coverImage: data['coverImage'],
      authorId: data['authorId'] ?? '',
      createdAt: data['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      status: data['status'] ?? 'draft',
      likesCount: data['likesCount'] ?? 0,
    );
  }

  // Convert Book to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'coverImage': coverImage,
      'authorId': authorId,
      'createdAt': createdAt,
      'status': status,
      'likesCount': likesCount,
    };
  }

  // Copy with method for updating book properties
  Book copyWith({
    String? id,
    String? title,
    String? description,
    String? coverImage,
    String? authorId,
    int? createdAt,
    String? status,
    int? likesCount,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      authorId: authorId ?? this.authorId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      likesCount: likesCount ?? this.likesCount,
    );
  }
}
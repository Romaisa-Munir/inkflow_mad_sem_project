class Book {
  final String id;
  final String title;
  final String description;
  final String? coverImage; // base64 string
  final String authorId;
  final int createdAt;
  final String status;

  Book({
    required this.id,
    required this.title,
    required this.description,
    this.coverImage,
    required this.authorId,
    required this.createdAt,
    this.status = 'draft',
  });
}
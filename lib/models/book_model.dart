import 'chapter_model.dart';

class Book {
  String title;
  String description;
  String? coverUrl; // Nullable cover URL

  Book({
    required this.title,
    required this.description,
    this.coverUrl,  // Optional cover URL
  });
}



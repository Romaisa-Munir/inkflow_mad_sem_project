import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../pages/BookDetailsPage.dart';

class BookCard extends StatelessWidget {
  final Book book;

  const BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.book, color: Colors.purple),
        title: Text(book.title),
        subtitle: Text(book.description, maxLines: 2, overflow: TextOverflow.ellipsis),
        onTap: () {
          // Navigate to BookDetailsPage and pass the Book object
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailsPage(
                book: book, // Pass the Book object directly
              ),
            ),
          );
        },
      ),
    );
  }
}

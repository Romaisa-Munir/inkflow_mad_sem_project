import 'package:flutter/material.dart';
import '../models/book_model.dart';
import 'create_book_page.dart';
import '../widgets/book_card.dart';

class WritingDashboard extends StatefulWidget {
  @override
  _WritingDashboardState createState() => _WritingDashboardState();
}

class _WritingDashboardState extends State<WritingDashboard> {
  List<Book> books = [];

  void _addBook(Book book) {
    setState(() {
      books.add(book);
    });
  }

  void _navigateToCreateBook() async {
    final newBook = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateBookPage(),
      ),
    );

    if (newBook != null && newBook is Book) {
      _addBook(newBook);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Stories"),
        backgroundColor: Colors.purple,
      ),
      body: books.isEmpty
          ? Center(
        child: Text(
          "No books yet. Tap + to create one!",
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, index) {
            return BookCard(book: books[index]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateBook,
        backgroundColor: Colors.purple,
        child: Icon(Icons.add),
      ),
    );
  }
}

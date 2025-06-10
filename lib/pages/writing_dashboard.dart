import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book_model.dart';
import 'create_book_page.dart';
import '../widgets/book_card.dart';

class WritingDashboard extends StatefulWidget {
  @override
  _WritingDashboardState createState() => _WritingDashboardState();
}

class _WritingDashboardState extends State<WritingDashboard> {
  List<Book> books = [];
  bool _isLoading = true;
  String? _errorMessage;

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final String userId = _auth.currentUser!.uid;
      final DatabaseEvent event = await _database.child('users/$userId/books').once();

      if (event.snapshot.exists) {
        final Map<dynamic, dynamic> booksData = event.snapshot.value as Map<dynamic, dynamic>;

        List<Book> fetchedBooks = [];
        booksData.forEach((key, value) {
          final Map<String, dynamic> bookMap = Map<String, dynamic>.from(value);

          final book = Book(
            id: bookMap['id'] ?? key,
            title: bookMap['title'] ?? 'Untitled',
            description: bookMap['description'] ?? 'No description',
            coverImage: bookMap['coverImage'], // base64 string or null
            authorId: bookMap['authorId'] ?? userId,
            createdAt: bookMap['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
            status: bookMap['status'] ?? 'draft',
          );

          fetchedBooks.add(book);
        });

        // Sort books by creation date (newest first)
        fetchedBooks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        setState(() {
          books = fetchedBooks;
          _isLoading = false;
        });
      } else {
        // No books found
        setState(() {
          books = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading books: ${e.toString()}';
      });
      print('Error fetching books: $e');
    }
  }

  void _addBook(Book book) {
    setState(() {
      books.insert(0, book); // Add new book at the beginning
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

  Future<void> _refreshBooks() async {
    await _fetchBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Stories"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshBooks,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            SizedBox(height: 16),
            Text('Loading your books...'),
          ],
        ),
      )
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshBooks,
              child: Text('Retry'),
            ),
          ],
        ),
      )
          : books.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              "No books yet. Tap + to create one!",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _refreshBooks,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              return BookCard(book: books[index]);
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateBook,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        child: Icon(Icons.add),
      ),
    );
  }
}
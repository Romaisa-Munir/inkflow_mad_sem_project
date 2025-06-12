import 'package:flutter/material.dart';
import 'package:standard_searchbar/old/standard_searchbar.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import '../../models/book_model.dart';
import 'book_detail.dart';

class Books extends StatefulWidget {
  @override
  BooksState createState() => BooksState();
}

class BooksState extends State<Books> {
  List<Book> allBooks = [];
  List<Book> filteredBooks = [];
  bool _isLoading = true;
  bool _disposed = false;
  String? _errorMessage;

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _loadAllBooks();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _loadAllBooks() async {
    if (_disposed) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      List<Book> books = [];

      // Get all users
      DatabaseEvent usersEvent = await _database.child('users').once();
      DataSnapshot usersSnapshot = usersEvent.snapshot;

      if (usersSnapshot.exists && usersSnapshot.value != null) {
        Map<dynamic, dynamic> usersData = usersSnapshot.value as Map<dynamic, dynamic>;

        // Iterate through each user to get their published books
        for (String userId in usersData.keys) {
          Map<dynamic, dynamic> userData = usersData[userId];

          if (userData['books'] != null) {
            Map<dynamic, dynamic> userBooks = userData['books'];

            userBooks.forEach((bookId, bookData) {
              if (bookData != null) {
                try {
                  Map<String, dynamic> bookMap = Map<String, dynamic>.from(bookData);

                  // Include both published and draft books for now (you can filter later)
                  Book book = Book(
                    id: bookMap['id'] ?? bookId,
                    title: bookMap['title'] ?? 'Untitled',
                    description: bookMap['description'] ?? 'No description',
                    coverImage: bookMap['coverImage'],
                    authorId: userId, // Use the userId from the loop, not from bookMap
                    createdAt: bookMap['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
                    status: bookMap['status'] ?? 'draft',
                  );
                  books.add(book);
                  print('Added book: ${book.title} with authorId: ${book.authorId}');
                } catch (e) {
                  print('Error parsing book $bookId: $e');
                }
              }
            });
          }
        }
      }

      // Sort books by creation date (newest first)
      books.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!_disposed && mounted) {
        setState(() {
          allBooks = books;
          filteredBooks = List.from(books);
          _isLoading = false;
        });
      }

      print('Loaded ${books.length} published books');
    } catch (e) {
      print('Error loading books: $e');
      if (!_disposed && mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading books: ${e.toString()}';
        });
      }
    }
  }

  void searchBooks(String query) {
    if (_disposed) return;

    final lower = query.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        filteredBooks = List.from(allBooks);
      });
      return;
    }

    setState(() {
      filteredBooks = allBooks.where((book) {
        final titleMatch = book.title.toLowerCase().contains(lower);
        final authorMatch = book.authorId.toLowerCase().contains(lower);
        return titleMatch || authorMatch;
      }).toList();
    });
  }

  Future<void> _refreshBooks() async {
    await _loadAllBooks();
  }

  Widget _buildBookCover(Book book, {double width = 80, double height = 100}) {
    if (book.coverImage != null && book.coverImage!.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(book.coverImage!),
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultBookCover(width, height);
          },
        );
      } catch (e) {
        return _buildDefaultBookCover(width, height);
      }
    }
    return _buildDefaultBookCover(width, height);
  }

  Widget _buildDefaultBookCover(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade300,
      child: Icon(Icons.book, size: width * 0.4, color: Colors.grey[600]),
    );
  }

  void _navigateToBookDetail(Book book) {
    Map<String, String> bookData = {
      'id': book.id,
      'title': book.title,
      'author': book.authorId,
      'description': book.description,
      'coverUrl': '',
      'status': book.status,
      'authorId': book.authorId, // Make sure this is set correctly
      'createdAt': book.createdAt.toString(),
    };

    print('Navigating to book detail with authorId: ${book.authorId}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetail(book: bookData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Books'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshBooks,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 20),

          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: StandardSearchBar(
              width: double.infinity,
              horizontalPadding: 10,
              onChanged: searchBooks,
            ),
          ),

          Expanded(
            child: _isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading books...'),
                ],
              ),
            )
                : _errorMessage != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(_errorMessage!, style: TextStyle(color: Colors.red)),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshBooks,
                    child: Text('Retry'),
                  ),
                ],
              ),
            )
                : filteredBooks.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    allBooks.isEmpty
                        ? "No published books available"
                        : "No books found",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _refreshBooks,
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: filteredBooks.length,
                itemBuilder: (context, index) {
                  final book = filteredBooks[index];
                  return GestureDetector(
                    onTap: () => _navigateToBookDetail(book),
                    child: Card(
                      margin: EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Book cover
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildBookCover(book),
                            ),
                            SizedBox(width: 16),
                            // Book details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    book.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "By ${book.authorId}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    book.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
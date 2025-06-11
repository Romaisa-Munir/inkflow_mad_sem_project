import 'package:flutter/material.dart';
import 'package:standard_searchbar/old/standard_searchbar.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../../models/book_model.dart';
import '../writing_dashboard.dart';
import '../profile/profile_page.dart';
import '../books/book_detail.dart';

class Library extends StatefulWidget {
  @override
  _LibraryState createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  List<Book> allLibraryBooks = [];
  List<Book> filteredBooks = [];
  bool _isLoading = true;
  bool _disposed = false;
  String? _errorMessage;

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadUserLibrary();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _loadUserLibrary() async {
    if (_disposed) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (!_disposed) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Please log in to view your library';
          });
        }
        return;
      }

      List<Book> libraryBooks = [];

      // Get user's library
      DatabaseEvent libraryEvent = await _database
          .child('users/${currentUser.uid}/library')
          .once();

      if (libraryEvent.snapshot.exists && libraryEvent.snapshot.value != null) {
        Map<dynamic, dynamic> libraryData = libraryEvent.snapshot.value as Map<dynamic, dynamic>;

        // For each book in library, fetch the actual book data
        for (String bookId in libraryData.keys) {
          // Search through all users to find this book
          DatabaseEvent usersEvent = await _database.child('users').once();
          if (usersEvent.snapshot.exists) {
            Map<dynamic, dynamic> usersData = usersEvent.snapshot.value as Map<dynamic, dynamic>;

            bool bookFound = false;
            for (String userId in usersData.keys) {
              Map<dynamic, dynamic> userData = usersData[userId];
              if (userData['books'] != null) {
                Map<dynamic, dynamic> userBooks = userData['books'];
                if (userBooks[bookId] != null) {
                  try {
                    Map<String, dynamic> bookMap = Map<String, dynamic>.from(userBooks[bookId]);
                    Book book = Book(
                      id: bookMap['id'] ?? bookId,
                      title: bookMap['title'] ?? 'Untitled',
                      description: bookMap['description'] ?? 'No description',
                      coverImage: bookMap['coverImage'],
                      authorId: bookMap['authorId'] ?? userId,
                      createdAt: bookMap['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
                      status: bookMap['status'] ?? 'published',
                    );
                    libraryBooks.add(book);
                    bookFound = true;
                    break;
                  } catch (e) {
                    print('Error parsing book $bookId: $e');
                  }
                }
              }
            }
            if (bookFound) break;
          }
        }
      }

      // Sort books by title
      libraryBooks.sort((a, b) => a.title.compareTo(b.title));

      if (!_disposed) {
        setState(() {
          allLibraryBooks = libraryBooks;
          filteredBooks = List.from(libraryBooks);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!_disposed) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading library: ${e.toString()}';
        });
      }
    }
  }

  void searchBooks(String query) {
    if (_disposed) return;

    final lower = query.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        filteredBooks = List.from(allLibraryBooks);
      });
      return;
    }

    setState(() {
      filteredBooks = allLibraryBooks.where((book) {
        final titleMatch = book.title.toLowerCase().contains(lower);
        final authorMatch = book.authorId.toLowerCase().contains(lower);
        return titleMatch || authorMatch;
      }).toList();
    });
  }

  Future<void> _refreshLibrary() async {
    await _loadUserLibrary();
  }

  Widget _buildBookCover(Book book, {double width = 80, double height = 80}) {
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
    };

    Navigator.pushNamed(
      context,
      '/book_detail',
      arguments: bookData,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Library'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshLibrary,
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
              )
          ),

          Expanded(
            child: _isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your library...'),
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
                    onPressed: _refreshLibrary,
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
                  Icon(Icons.library_books, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    allLibraryBooks.isEmpty
                        ? "Your library is empty"
                        : "No books found",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  if (allLibraryBooks.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        "Add books to your library to see them here",
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _refreshLibrary,
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
                              child: _buildBookCover(book, width: 80, height: 100),
                            ),
                            SizedBox(width: 16),
                            // Book details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    book.title,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "By ${book.authorId}",
                                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    book.description,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_rounded), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.my_library_books_rounded), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: 2, // Library Index
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/');
          }
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WritingDashboard()),
            );
          }
          if (index == 2) {
            // Already on library, do nothing
            return;
          }
          if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          }
        },
      ),
    );
  }
}
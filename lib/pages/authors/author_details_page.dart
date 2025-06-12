import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import '../../models/author_model.dart';
import '../../models/book_model.dart';
import '../books/book_detail.dart';

class AuthorDetailsPage extends StatefulWidget {
  final AuthorModel author;

  const AuthorDetailsPage({Key? key, required this.author}) : super(key: key);

  @override
  _AuthorDetailsPageState createState() => _AuthorDetailsPageState();
}

class _AuthorDetailsPageState extends State<AuthorDetailsPage> {
  List<Book> authorBooks = [];
  bool _isLoading = true;
  bool _disposed = false;
  String? _errorMessage;

  // Dynamic author stats that get recalculated
  int _currentTotalLikes = 0;
  int _currentBookCount = 0;
  String _currentAuthorName = '';

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _currentAuthorName = widget.author.name; // Initialize with passed name
    _loadAuthorBooks();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _loadAuthorBooks() async {
    if (_disposed) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      List<Book> books = [];
      int totalLikes = 0;

      print('Loading books for author ID: ${widget.author.id}');

      // Get books from the specific author's collection
      DatabaseEvent booksEvent = await _database
          .child('users/${widget.author.id}/books')
          .once();

      print('Books snapshot exists: ${booksEvent.snapshot.exists}');

      if (booksEvent.snapshot.exists && booksEvent.snapshot.value != null) {
        Map<dynamic, dynamic> booksData = booksEvent.snapshot.value as Map<dynamic, dynamic>;

        print('Found ${booksData.length} books for author');

        for (var bookEntry in booksData.entries) {
          final String bookId = bookEntry.key;
          final Map<String, dynamic> bookMap = Map<String, dynamic>.from(bookEntry.value);

          try {
            print('Processing book: ${bookMap['title']} with status: ${bookMap['status']}');

            // Get the current likes count for this book from the global likes node
            DatabaseEvent likesEvent = await _database
                .child('books/$bookId/likes')
                .once();

            int likesCount = 0;
            if (likesEvent.snapshot.exists && likesEvent.snapshot.value != null) {
              Map<dynamic, dynamic> likesData = likesEvent.snapshot.value as Map<dynamic, dynamic>;
              likesCount = likesData.length;
            }

            // Add to total likes
            totalLikes += likesCount;

            // Update the book's likesCount in the author's collection if needed
            if (bookMap['likesCount'] != likesCount) {
              await _database
                  .child('users/${widget.author.id}/books/$bookId/likesCount')
                  .set(likesCount);
            }

            // Create book with updated likes count
            Book book = Book(
              id: bookId,
              title: bookMap['title'] ?? 'Untitled',
              description: bookMap['description'] ?? 'No description',
              coverImage: bookMap['coverImage'],
              authorId: bookMap['authorId'] ?? widget.author.id,
              createdAt: bookMap['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
              status: bookMap['status'] ?? 'draft',
              likesCount: likesCount, // Use the current likes count
            );

            books.add(book);
            print('Added book: ${book.title} with ${book.likesCount} likes');
          } catch (e) {
            print('Error parsing book $bookId: $e');
          }
        }
      } else {
        print('No books found for author ${widget.author.id}');
      }

      // Sort books by likes count first, then by creation date (newest first)
      books.sort((a, b) {
        final likesComparison = b.likesCount.compareTo(a.likesCount);
        if (likesComparison != 0) return likesComparison;
        return b.createdAt.compareTo(a.createdAt);
      });

      print('Final book count: ${books.length}, Total likes: $totalLikes');

      // Update the author's total likes in the database
      await _updateAuthorTotalLikes(totalLikes, books.length);

      if (!_disposed && mounted) {
        setState(() {
          authorBooks = books;
          _currentTotalLikes = totalLikes;
          _currentBookCount = books.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading author books: $e');
      if (!_disposed && mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading books: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _updateAuthorTotalLikes(int totalLikes, int bookCount) async {
    try {
      print('Updating author ${widget.author.id} total likes to: $totalLikes');

      // Update author's profile with current totals
      Map<String, dynamic> authorUpdates = {
        'totalLikes': totalLikes,
        'likes': totalLikes,
        'bookCount': bookCount,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };

      // Update in multiple locations for consistency
      List<Future> updateFutures = [
        _database.child('users/${widget.author.id}/profile').update(authorUpdates),
        _database.child('users/${widget.author.id}').update(authorUpdates),
      ];

      await Future.wait(updateFutures);
      print('Author total likes updated successfully');
    } catch (e) {
      print('Error updating author total likes: $e');
    }
  }

  Future<void> _refreshAuthorData() async {
    print('Refreshing author data...');
    await _loadAuthorBooks();

    if (!_disposed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Author data refreshed'),
          duration: Duration(milliseconds: 500),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildAuthorImage() {
    if (widget.author.profileImageUrl != null) {
      if (widget.author.profileImageUrl!.startsWith('data:image')) {
        try {
          final base64String = widget.author.profileImageUrl!.split(',')[1];
          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
          );
        } catch (e) {
          return _buildDefaultAvatar();
        }
      } else {
        return Image.network(
          widget.author.profileImageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
        );
      }
    }
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.7),
            Theme.of(context).primaryColor,
          ],
        ),
      ),
      child: Center(
        child: Text(
          _currentAuthorName.isNotEmpty ? _currentAuthorName[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBookCover(Book book) {
    if (book.coverImage != null && book.coverImage!.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(book.coverImage!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultBookCover(),
        );
      } catch (e) {
        return _buildDefaultBookCover();
      }
    }
    return _buildDefaultBookCover();
  }

  Widget _buildDefaultBookCover() {
    return Container(
      color: Colors.grey.shade300,
      child: Icon(
        Icons.book,
        size: 50,
        color: Colors.grey[600],
      ),
    );
  }

  void _navigateToBookDetail(Book book) async {
    // Convert all values to String as BookDetail expects Map<String, String>
    Map<String, String> bookData = {
      'id': book.id,
      'title': book.title,
      'author': _currentAuthorName,
      'description': book.description,
      'coverUrl': '', // BookDetail expects this field
      'status': book.status,
      'authorId': book.authorId,
      'createdAt': book.createdAt.toString(), // Convert to string
    };

    // Navigate and wait for result
    final result = await Navigator.pushNamed(
      context,
      '/book_detail',
      arguments: bookData,
    );

    // Refresh author books data when returning from book detail
    // This ensures we see updated like counts
    print('Returned from BookDetail, refreshing author books...');
    await _loadAuthorBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Author Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshAuthorData,
            tooltip: 'Refresh author data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Header - NOW USES DYNAMIC DATA
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Author Profile Picture
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade300,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: _buildAuthorImage(),
                      ),
                    ),
                    SizedBox(width: 20),

                    // Author Info - NOW USES DYNAMIC STATS
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentAuthorName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            widget.author.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.book, size: 16, color: Theme.of(context).primaryColor),
                              SizedBox(width: 4),
                              Text(
                                "$_currentBookCount ${_currentBookCount == 1 ? 'book' : 'books'}",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              SizedBox(width: 16),
                              Icon(Icons.favorite, size: 16, color: Colors.red),
                              SizedBox(width: 4),
                              Text(
                                "$_currentTotalLikes likes",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Books Section
            Text(
              'Published Books',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // Books Content
            _isLoading
                ? Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
                : _errorMessage != null
                ? Center(
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 8),
                  Text(_errorMessage!, style: TextStyle(color: Colors.red)),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAuthorBooks,
                    child: Text('Retry'),
                  ),
                ],
              ),
            )
                : authorBooks.isEmpty
                ? Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.book_outlined, size: 64, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'No published books yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
                : GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: authorBooks.length,
              itemBuilder: (context, index) {
                final book = authorBooks[index];
                return GestureDetector(
                  onTap: () => _navigateToBookDetail(book),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Book Cover
                        Expanded(
                          flex: 3,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: _buildBookCover(book),
                            ),
                          ),
                        ),
                        // Book Info
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  book.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // Show likes count for each book
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.favorite,
                                      size: 14,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '${book.likesCount}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
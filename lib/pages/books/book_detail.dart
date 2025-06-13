import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'book_reader_page.dart';
import 'package:inkflow_mad_sem_project/services/reading_analytics_service.dart';


class BookDetail extends StatefulWidget {
  final Map<String, String> book;

  const BookDetail({super.key, required this.book});

  @override
  State<BookDetail> createState() => _BookDetailState();
}

class _BookDetailState extends State<BookDetail> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLiked = false;
  bool _isInLibrary = false;
  bool _isLoading = false;
  int _likesCount = 0;
  String? _authorName;
  String? _coverImageBase64;
  List<Map<String, dynamic>> _chapters = [];

  @override
  void initState() {
    super.initState();
    print('BookDetail initialized with book data: ${widget.book}');
    print('Author ID: ${widget.book['authorId']}');
    _loadBookDetails();
    _checkUserInteractions();
  }

  Future<void> _loadBookDetails() async {
    try {
      // Load author details
      await _loadAuthorDetails();

      // Load book cover and chapters
      await _loadBookData();

      // Load likes count
      await _loadLikesCount();
    } catch (e) {
      print('Error loading book details: $e');
    }
  }

  Future<void> _loadAuthorDetails() async {
    try {
      String? authorId = widget.book['authorId'];
      if (authorId == null || authorId == 'null') {
        print('Author ID is null, cannot load author details');
        setState(() {
          _authorName = widget.book['author'] ?? 'Unknown Author';
        });
        return;
      }

      print('Loading author details for authorId: $authorId');

      String? authorName;

      // Try loading from profile first
      DatabaseEvent profileEvent = await _database
          .child('users/$authorId/profile')
          .once();

      if (profileEvent.snapshot.exists && profileEvent.snapshot.value != null) {
        Map<dynamic, dynamic> profileData = profileEvent.snapshot.value as Map<dynamic, dynamic>;

        // Check for username in profile (this is the main field we want)
        authorName = profileData['username'];

        // If username is null, empty, or still default, try other profile fields
        if (authorName == null || authorName.isEmpty || authorName == 'Your Username') {
          authorName = profileData['name'];
        }

        print('Profile data found: $profileData');
        print('Extracted author name from profile: $authorName');
      }

      // If no good name from profile, try root level user data
      if (authorName == null || authorName.isEmpty || authorName == 'Your Username') {
        DatabaseEvent userEvent = await _database
            .child('users/$authorId')
            .once();

        if (userEvent.snapshot.exists && userEvent.snapshot.value != null) {
          Map<dynamic, dynamic> userData = userEvent.snapshot.value as Map<dynamic, dynamic>;

          // Try various fields in order of preference
          authorName = userData['name'] ??
              userData['displayName'] ??
              userData['username'];

          print('User data found, extracted name: $authorName');
        }
      }

      // If still no good name, create a user-friendly fallback
      if (authorName == null || authorName.isEmpty || authorName == 'Your Username') {
        // Get user's email to create a better fallback
        DatabaseEvent userEvent = await _database
            .child('users/$authorId')
            .once();

        String? email;
        if (userEvent.snapshot.exists && userEvent.snapshot.value != null) {
          Map<dynamic, dynamic> userData = userEvent.snapshot.value as Map<dynamic, dynamic>;
          email = userData['email'];
        }

        if (email != null && email.isNotEmpty) {
          // Use email prefix as fallback (e.g., "john.doe@example.com" -> "john.doe")
          authorName = email.split('@')[0];
          print('Using email prefix as author name: $authorName');
        } else {
          // Last resort: use the book's author field or generic name
          authorName = widget.book['author'] ?? 'Author';
          print('Using fallback author name: $authorName');
        }
      }

      setState(() {
        _authorName = authorName;
      });

      print('Final author name set: $_authorName');

    } catch (e) {
      print('Error loading author details: $e');
      setState(() {
        _authorName = widget.book['author'] ?? 'Unknown Author';
      });
    }
  }

  Future<void> _loadBookData() async {
    try {
      String? authorId = widget.book['authorId'];
      String? bookId = widget.book['id'];

      if (authorId == null || authorId == 'null' || bookId == null) {
        print('Invalid authorId ($authorId) or bookId ($bookId)');
        return;
      }

      print('Loading book data for bookId: $bookId, authorId: $authorId');

      DatabaseEvent bookEvent = await _database
          .child('users/$authorId/books/$bookId')
          .once();

      if (bookEvent.snapshot.exists && bookEvent.snapshot.value != null) {
        Map<dynamic, dynamic> bookData = bookEvent.snapshot.value as Map<dynamic, dynamic>;
        print('Book data loaded: ${bookData.keys}');

        setState(() {
          _coverImageBase64 = bookData['coverImage'];
        });

        // Load chapters
        if (bookData['chapters'] != null) {
          Map<dynamic, dynamic> chaptersData = bookData['chapters'];
          List<Map<String, dynamic>> chapters = [];

          print('Found ${chaptersData.length} chapters');

          chaptersData.forEach((chapterId, chapterData) {
            if (chapterData != null) {
              Map<String, dynamic> chapter = {
                'id': chapterId,
                'title': chapterData['title'] ?? 'Untitled Chapter',
                'content': chapterData['content'] ?? '',
                'order': chapterData['order'] ?? chapters.length, // Use index as fallback
              };
              chapters.add(chapter);
              print('Chapter loaded: ${chapter['title']} (order: ${chapter['order']}, content: ${chapter['content']?.toString().length ?? 0} chars)');
            }
          });

          // Sort chapters by order
          chapters.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

          setState(() {
            _chapters = chapters;
          });

          print('Total chapters loaded and sorted: ${chapters.length}');
        } else {
          print('No chapters found in book data');
          setState(() {
            _chapters = [];
          });

        }
      } else {
        print('Book data not found at users/$authorId/books/$bookId');
      }
    } catch (e) {
      print('Error loading book data: $e');
    }
  }

  Future<void> _loadLikesCount() async {
    try {
      String? authorId = widget.book['authorId'];
      String? bookId = widget.book['id'];

      if (authorId == null || authorId == 'null' || bookId == null) {
        print('Invalid authorId ($authorId) or bookId ($bookId)');
        return;
      }

      // Load likes count from the book's likes node
      DatabaseEvent likesEvent = await _database
          .child('books/$bookId/likes')
          .once();

      int likesCount = 0;
      if (likesEvent.snapshot.exists && likesEvent.snapshot.value != null) {
        Map<dynamic, dynamic> likesData = likesEvent.snapshot.value as Map<dynamic, dynamic>;
        likesCount = likesData.length;
      }

      setState(() {
        _likesCount = likesCount;
      });

      print('Loaded likes count for book $bookId: $likesCount');
    } catch (e) {
      print('Error loading likes count: $e');
    }
  }


  Future<void> _checkUserInteractions() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Check if book is liked
      DatabaseEvent likeEvent = await _database
          .child('books/${widget.book['id']}/likes/${currentUser.uid}')
          .once();

      setState(() {
        _isLiked = likeEvent.snapshot.exists;
      });

      // Check if book is in library
      DatabaseEvent libraryEvent = await _database
          .child('users/${currentUser.uid}/library/${widget.book['id']}')
          .once();

      setState(() {
        _isInLibrary = libraryEvent.snapshot.exists;
      });
    } catch (e) {
      print('Error checking user interactions: $e');
    }
  }

// Replace the _toggleLike method in BookDetail
  Future<void> _toggleLike() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      _showMessage('Please log in to like books');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? bookId = widget.book['id'];
      String? authorId = widget.book['authorId'];

      if (bookId == null || authorId == null || authorId == 'null') {
        _showMessage('Invalid book or author data');
        return;
      }

      print('Toggling like for book: $bookId, author: $authorId, user: ${currentUser.uid}');

      final bookLikesRef = _database.child('books/$bookId/likes/${currentUser.uid}');

      if (_isLiked) {
        // Remove like
        print('Removing like...');
        await bookLikesRef.remove();
        setState(() {
          _isLiked = false;
          _likesCount = _likesCount > 0 ? _likesCount - 1 : 0;
        });
        print('Like removed, new count: $_likesCount');
      } else {
        // Add like
        print('Adding like...');
        await bookLikesRef.set({
          'userId': currentUser.uid,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        setState(() {
          _isLiked = true;
          _likesCount++;
        });
        print('Like added, new count: $_likesCount');
      }

      // Update the book's likesCount in the author's collection immediately
      await _database
          .child('users/$authorId/books/$bookId/likesCount')
          .set(_likesCount);

      // Update author's total likes immediately (this is the key fix)
      await _updateAuthorLikesImmediately(authorId);

      _showMessage(_isLiked ? 'Liked!' : 'Like removed');

    } catch (e) {
      print('Error toggling like: $e');
      _showMessage('Error updating like: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

// New method for immediate author likes update
  Future<void> _updateAuthorLikesImmediately(String authorId) async {
    try {
      print('Immediately updating author total likes for authorId: $authorId');

      // Get all books by this author
      DatabaseEvent authorBooksEvent = await _database
          .child('users/$authorId/books')
          .once();

      int totalLikes = 0;
      int totalBooks = 0;

      if (authorBooksEvent.snapshot.exists && authorBooksEvent.snapshot.value != null) {
        Map<dynamic, dynamic> booksData = authorBooksEvent.snapshot.value as Map<dynamic, dynamic>;
        totalBooks = booksData.length;
        print('Found $totalBooks books for author');

        // Count likes for each book
        for (String bookId in booksData.keys) {
          DatabaseEvent bookLikesEvent = await _database
              .child('books/$bookId/likes')
              .once();

          if (bookLikesEvent.snapshot.exists && bookLikesEvent.snapshot.value != null) {
            Map<dynamic, dynamic> likesData = bookLikesEvent.snapshot.value as Map<dynamic, dynamic>;
            int bookLikes = likesData.length;
            totalLikes += bookLikes;
            print('Book $bookId has $bookLikes likes');

            // Update the book's likesCount in the author's books collection
            await _database
                .child('users/$authorId/books/$bookId/likesCount')
                .set(bookLikes);
          }
        }
      }

      print('Total likes across all books for author: $totalLikes');

      // Update author's profile with total likes and book count in multiple locations
      Map<String, dynamic> authorUpdates = {
        'totalLikes': totalLikes,
        'likes': totalLikes, // Keep both for compatibility
        'bookCount': totalBooks,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };

      // Update in multiple locations simultaneously for immediate effect
      List<Future> updateFutures = [
        _database.child('users/$authorId/profile/totalLikes').set(totalLikes),
        _database.child('users/$authorId/profile/likes').set(totalLikes),
        _database.child('users/$authorId/totalLikes').set(totalLikes),
        _database.child('users/$authorId/likes').set(totalLikes),
        _database.child('users/$authorId/profile').update(authorUpdates),
        _database.child('users/$authorId').update(authorUpdates),
      ];

      await Future.wait(updateFutures);

      print('Author stats immediately updated: $totalLikes likes, $totalBooks books');

      // Force refresh of any cached author data by triggering a database listener
      // This ensures the Authors page will see the updated data immediately
      await _database.child('users/$authorId/lastLikeUpdate').set(DateTime.now().millisecondsSinceEpoch);

    } catch (e) {
      print('Error immediately updating author likes: $e');
    }
  }
  Future<void> _toggleLibrary() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      _showMessage('Please log in to add books to your library');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final libraryRef = _database.child('users/${currentUser.uid}/library/${widget.book['id']}');

      if (_isInLibrary) {
        // Remove from library
        await libraryRef.remove();
        setState(() {
          _isInLibrary = false;
        });
        _showMessage('Removed from library');
      } else {
        // Add to library
        await libraryRef.set({
          'bookId': widget.book['id'],
          'addedAt': DateTime.now().millisecondsSinceEpoch,
        });
        setState(() {
          _isInLibrary = true;
        });
        _showMessage('Added to library');
      }
    } catch (e) {
      print('Error toggling library: $e');
      _showMessage('Error updating library');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToReader() async {
    if (_chapters.isEmpty) {
      _showMessage('No chapters available to read');
      return;
    }

    print('Navigating to reader with ${_chapters.length} chapters');
    print('First chapter: ${_chapters[0]}');

    // Track the read action using analytics service
    try {
      String? bookId = widget.book['id'];
      if (bookId != null) {
        await ReadingAnalyticsService.incrementReadCount(bookId);
        print('Read count incremented for book: $bookId');
      }
    } catch (e) {
      print('Error tracking read: $e');
      // Don't block navigation if tracking fails
    }

    // Navigate to the separate BookReaderPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookReaderPage(
          chapters: _chapters,
          bookTitle: widget.book['title'] ?? 'Book',
          bookId: widget.book['id'],  // Add this line
        ),
      ),
    ).catchError((error) {
      print('Navigation error: $error');
      _showMessage('Error opening reader');
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildBookCover() {
    if (_coverImageBase64 != null && _coverImageBase64!.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(_coverImageBase64!),
          width: 120,
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultCover();
          },
        );
      } catch (e) {
        return _buildDefaultCover();
      }
    }
    return _buildDefaultCover();
  }

  Widget _buildDefaultCover() {
    return Container(
      width: 120,
      height: 180,
      color: Colors.grey.shade300,
      child: Icon(Icons.book, size: 60, color: Colors.grey[600]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover and basic info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildBookCover(),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.book['title']!,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'By ${_authorName ?? widget.book['author']!}',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.favorite, color: Colors.red, size: 20),
                          SizedBox(width: 4),
                          Text('$_likesCount likes'),
                          SizedBox(width: 16),
                          Icon(Icons.book, size: 20),
                          SizedBox(width: 4),
                          Text('${_chapters.length} chapters'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 24),

            // Description
            Text(
              'Description',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              widget.book['description']!,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),

            SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _chapters.isNotEmpty ? _navigateToReader : null,
                    icon: Icon(Icons.menu_book),
                    label: Text('Read'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _toggleLike,
                    icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border),
                    label: Text(_isLiked ? 'Liked' : 'Like'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLiked ? Colors.red : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _toggleLibrary,
                    icon: Icon(_isInLibrary ? Icons.library_add_check : Icons.library_add),
                    label: Text(_isInLibrary ? 'In Library' : 'Add to Library'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isInLibrary ? Colors.green : Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showMessage('Purchase feature coming soon!');
                    },
                    icon: Icon(Icons.shopping_cart),
                    label: Text('Buy'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            if (_isLoading)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

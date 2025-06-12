import 'package:flutter/material.dart';
import 'package:standard_searchbar/old/standard_searchbar.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../../models/book_model.dart';
import '../../models/author_model.dart';
import '../../services/author_service.dart';
import '../authors/author_details_page.dart';
import '../writing_dashboard.dart';
import '../profile/profile_page.dart';
import '../books/book_detail.dart';

class HomeScreen extends StatefulWidget {
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // Real data from Firebase
  List<Book> allBooks = [];
  List<Book> filteredBooks = [];
  List<AuthorModel> allAuthors = [];
  List<AuthorModel> filteredAuthors = [];
  List<Book> userLibraryBooks = [];

  bool isLoading = true;
  bool _disposed = false; // Add this flag

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh data when app comes back to foreground
    if (state == AppLifecycleState.resumed && !_disposed) {
      print('App resumed, refreshing data...');
      _loadAllAuthors(); // Refresh authors to get latest likes
    }
  }

  Future<void> _loadData() async {
    if (_disposed) return; // Check if disposed

    setState(() {
      isLoading = true;
    });

    try {
      // Load books and authors first
      await Future.wait([
        _loadAllBooks(),
        _loadAllAuthors(),
      ]);

      // Then load user library after books are loaded
      await _loadUserLibrary();

    } catch (e) {
      print('Error loading data: $e');
    }

    if (!_disposed) { // Check if disposed before setState
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadAllBooks() async {
    try {
      List<Book> books = [];

      // Get all users
      DatabaseEvent usersEvent = await _database.child('users').once();
      DataSnapshot usersSnapshot = usersEvent.snapshot;

      if (usersSnapshot.exists && usersSnapshot.value != null) {
        Map<dynamic, dynamic> usersData = usersSnapshot.value as Map<dynamic, dynamic>;

        // Iterate through each user to get their books
        for (String userId in usersData.keys) {
          Map<dynamic, dynamic> userData = usersData[userId];

          if (userData['books'] != null) {
            Map<dynamic, dynamic> userBooks = userData['books'];

            userBooks.forEach((bookId, bookData) {
              if (bookData != null) {
                try {
                  Map<String, dynamic> bookMap = Map<String, dynamic>.from(bookData);
                  Book book = Book(
                    id: bookMap['id'] ?? bookId,
                    title: bookMap['title'] ?? 'Untitled',
                    description: bookMap['description'] ?? 'No description',
                    coverImage: bookMap['coverImage'],
                    authorId: userId, // Use the userId from the loop, not from bookMap
                    createdAt: bookMap['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
                    status: bookMap['status'] ?? 'draft',
                    likesCount: bookMap['likesCount'] ?? 0, // Include likes count
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

      if (!_disposed) { // Check if disposed before setState
        setState(() {
          allBooks = books;
          filteredBooks = List.from(books);
        });
      }

      print('Loaded ${books.length} books');
    } catch (e) {
      print('Error loading books: $e');
    }
  }

  Future<void> _loadAllAuthors() async {
    try {
      List<AuthorModel> authors = await AuthorService.fetchAuthors();
      if (!_disposed) { // Check if disposed before setState
        setState(() {
          allAuthors = authors;
          filteredAuthors = List.from(authors);
        });
      }
      print('Loaded ${authors.length} authors');
    } catch (e) {
      print('Error loading authors: $e');
    }
  }

  // Helper method to load book directly if not found in allBooks
  Future<void> _loadBookDirectly(String bookId, List<Book> libraryBooks) async {
    try {
      print('Searching for book $bookId directly in Firebase');

      // Search through all users to find this book
      DatabaseEvent usersEvent = await _database.child('users').once();

      if (usersEvent.snapshot.exists && usersEvent.snapshot.value != null) {
        Map<dynamic, dynamic> usersData = usersEvent.snapshot.value as Map<dynamic, dynamic>;

        for (String userId in usersData.keys) {
          Map<dynamic, dynamic> userData = usersData[userId];

          if (userData['books'] != null) {
            Map<dynamic, dynamic> userBooks = userData['books'];

            if (userBooks.containsKey(bookId)) {
              Map<String, dynamic> bookData = Map<String, dynamic>.from(userBooks[bookId]);

              Book book = Book(
                id: bookData['id'] ?? bookId,
                title: bookData['title'] ?? 'Untitled',
                description: bookData['description'] ?? 'No description',
                coverImage: bookData['coverImage'],
                authorId: userId,
                createdAt: bookData['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
                status: bookData['status'] ?? 'published',
                likesCount: bookData['likesCount'] ?? 0,
              );

              libraryBooks.add(book);
              print('Found and added book directly: ${book.title}');
              return;
            }
          }
        }
      }

      print('Book $bookId not found anywhere');
    } catch (e) {
      print('Error loading book $bookId directly: $e');
    }
  }

  //Changes from warda: Had to make tiny changes in this function, to maintain user's login session.
  Future<void> _loadUserLibrary() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('No user logged in, cannot load library');
        if (!_disposed) {
          setState(() {
            userLibraryBooks = [];
          });
        }
        return;
      }

      List<Book> libraryBooks = [];

      print('Loading library for user: ${currentUser.uid}');

      // Get user's library
      DatabaseEvent libraryEvent = await _database
          .child('users/${currentUser.uid}/library')
          .once();

      if (libraryEvent.snapshot.exists && libraryEvent.snapshot.value != null) {
        Map<dynamic, dynamic> libraryData = libraryEvent.snapshot.value as Map<dynamic, dynamic>;
        print('Found ${libraryData.length} books in user library');

        // Get book details for each book in library
        for (String bookId in libraryData.keys) {
          // Find the book in allBooks
          Book? foundBook;
          try {
            foundBook = allBooks.firstWhere((b) => b.id == bookId);
            libraryBooks.add(foundBook);
            print('Added library book: ${foundBook.title}');
          } catch (e) {
            // Book not found in allBooks, try to load it directly
            print('Book with id $bookId not found in allBooks, trying direct load');
            await _loadBookDirectly(bookId, libraryBooks);
          }
        }
      } else {
        print('No library data found for user');
      }

      if (!_disposed) { // Check if disposed before setState
        setState(() {
          userLibraryBooks = libraryBooks;
        });
      }

      print('Loaded ${libraryBooks.length} library books');
    } catch (e) {
      print('Error loading user library: $e');
      if (!_disposed) {
        setState(() {
          userLibraryBooks = [];
        });
      }
    }
  }

  // Add refresh method for the refresh button
  Future<void> _refreshData() async {
    // Show loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('Refreshing...'),
          ],
        ),
        duration: Duration(seconds: 3),
      ),
    );

    // Refresh all data
    await _loadData();

    // Show success message
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Refreshed successfully!'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Enhanced refresh method that focuses on authors
  Future<void> _refreshAuthorsOnly() async {
    try {
      print('Refreshing authors data...');
      await _loadAllAuthors();

      if (!_disposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Author data refreshed'),
            duration: Duration(milliseconds: 500),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      print('Error refreshing authors: $e');
    }
  }

  // Add a pull-to-refresh for the entire page
  Future<void> _onRefresh() async {
    await _loadData();
  }

  void searchAll(String query) {
    if (_disposed) return; // Check if disposed

    final lower = query.toLowerCase();
    setState(() {
      filteredBooks = allBooks.where((book) =>
      book.title.toLowerCase().contains(lower) ||
          book.authorId.toLowerCase().contains(lower)
      ).toList();

      filteredAuthors = allAuthors.where((author) =>
          author.name.toLowerCase().contains(lower)
      ).toList();
    });
  }

  Widget _buildBookCover(Book book, {double width = 150, double height = 200}) {
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
      child: Icon(Icons.book, size: width * 0.3, color: Colors.grey[600]),
    );
  }

  Widget _buildAuthorAvatar(AuthorModel author) {
    if (author.profileImageUrl != null) {
      if (author.profileImageUrl!.startsWith('data:image')) {
        try {
          final base64String = author.profileImageUrl!.split(',')[1];
          final bytes = base64Decode(base64String);
          return CircleAvatar(
            radius: 25,
            backgroundImage: MemoryImage(bytes),
          );
        } catch (e) {
          return _buildDefaultAuthorAvatar(author.name);
        }
      }
    }
    return _buildDefaultAuthorAvatar(author.name);
  }

  Widget _buildDefaultAuthorAvatar(String name) {
    return CircleAvatar(
      radius: 25,
      backgroundColor: Colors.grey.shade300,
      child: Text(
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'A',
        style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Navigate to book detail with refresh on return
  void _navigateToBookDetail(Book book) async {
    // Convert Book to the format your BookDetail expects
    Map<String, String> bookData = {
      'id': book.id,
      'title': book.title,
      'author': book.authorId, // You might want to get the actual author name
      'description': book.description,
      'coverUrl': '', // You'll handle this in BookDetail
      'authorId': book.authorId, // Make sure this is set correctly
      'status': book.status,
      'createdAt': book.createdAt.toString(),
    };

    print('Navigating to book detail with authorId: ${book.authorId}');

    // Wait for the result from BookDetail page
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetail(book: bookData),
      ),
    );

    // Refresh data when returning to ensure likes are updated
    print('Returned from BookDetail, refreshing data...');
    await Future.wait([
      _loadAllBooks(),
      _loadAllAuthors(),
    ]);
  }

  // Add a method to handle navigation to author details
  Future<void> _navigateToAuthorDetails(AuthorModel author) async {
    print('Navigating to author details for: ${author.name}');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AuthorDetailsPage(author: author),
      ),
    );

    // Always refresh author data when returning
    print('Returned from AuthorDetailsPage, refreshing author data...');
    await _loadAllAuthors();

    // Optional: Show a brief loading indicator
    if (!_disposed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated author data'),
          duration: Duration(milliseconds: 800),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Inkflow'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: isLoading ? null : _refreshData, // Disable when already loading
              tooltip: 'Refresh all data',
            ),
          ],
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Inkflow'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh all data',
          ),
          // Add a specific button to refresh just authors
          IconButton(
            icon: Icon(Icons.people_outline),
            onPressed: _refreshAuthorsOnly,
            tooltip: 'Refresh authors',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 20),

              // Search Bar
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: StandardSearchBar(
                    width: double.infinity,
                    horizontalPadding: 10,
                    onChanged: searchAll,
                  )
              ),

              // 'Books' Title with "See All" option
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Books", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/all_books');
                      },
                      child: Text("See All", style: TextStyle(color: Colors.deepPurple)),
                    )
                  ],
                ),
              ),

              // Book Section - horizontal scrollable
              SizedBox(
                height: 240,
                child: filteredBooks.isEmpty
                    ? Center(
                  child: Text(
                    'No books available yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                )
                    : ListView.builder(
                  itemCount: filteredBooks.length,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  itemBuilder: (context, index) {
                    final book = filteredBooks[index];
                    return GestureDetector(
                        onTap: () => _navigateToBookDetail(book),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Book Cover
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildBookCover(book),
                              ),
                              SizedBox(height: 5),
                              // Book Title
                              Container(
                                width: 150,
                                height: 35,
                                child: Text(
                                  book.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        )
                    );
                  },
                ),
              ),

              // 'My Library' section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("My Library", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/library');
                      },
                      child: Text("See All", style: TextStyle(color: Colors.deepPurple)),
                    )
                  ],
                ),
              ),

              // My Library (horizontally scrollable)
              Container(
                height: 160,
                margin: EdgeInsets.only(bottom: 5),
                child: userLibraryBooks.isEmpty
                    ? Center(
                  child: Text(
                    'Your library is empty',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                )
                    : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: userLibraryBooks.length,
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  itemBuilder: (context, index) {
                    final book = userLibraryBooks[index];
                    return GestureDetector(
                      onTap: () => _navigateToBookDetail(book),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildBookCover(book, width: 100, height: 120),
                            ),
                            SizedBox(height: 5),
                            Container(
                              width: 100,
                              child: Text(
                                book.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 'Authors' title with "See All" option
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Authors", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/all_authors');
                      },
                      child: Text("See All", style: TextStyle(color: Colors.deepPurple)),
                    )
                  ],
                ),
              ),

              // Author Section with updated navigation
              Container(
                height: 80,
                margin: EdgeInsets.only(bottom: 20),
                child: filteredAuthors.isEmpty
                    ? Center(
                  child: Text(
                    'No authors available yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                )
                    : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: filteredAuthors.length,
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  itemBuilder: (context, index) {
                    final author = filteredAuthors[index];
                    return GestureDetector(
                      onTap: () => _navigateToAuthorDetails(author),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildAuthorAvatar(author),
                            SizedBox(height: 4),
                            Container(
                              width: 70,
                              child: Text(
                                author.name,
                                style: TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom Nav Bar
      //From Warda: Made changes in navigation. Navigation flow remains same, had navigation issues so had to edit code for proper navigation
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_rounded), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.my_library_books_rounded), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            // Already on home, do nothing
            return;
          }
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WritingDashboard()),
            );
          }
          if (index == 2) {
            Navigator.pushNamed(context, '/library');
          }
          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          }
        },
      ),
    );
  }
}
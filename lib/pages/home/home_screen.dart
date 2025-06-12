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

class HomeScreenState extends State<HomeScreen> {
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
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_disposed) return; // Check if disposed

    setState(() {
      isLoading = true;
    });

    try {
      // Load all books and authors concurrently
      await Future.wait([
        _loadAllBooks(),
        _loadAllAuthors(),
        _loadUserLibrary(),
      ]);
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
                    authorId: bookMap['authorId'] ?? userId,
                    createdAt: bookMap['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
                    status: bookMap['status'] ?? 'draft',
                  );
                  books.add(book);
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
//Changes from warda: Had to make tiny changes in this function, to maintain user's login session.

  Future<void> _loadUserLibrary() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      List<Book> libraryBooks = [];

      // Get user's library
      DatabaseEvent libraryEvent = await _database
          .child('users/${currentUser.uid}/library')
          .once();

      if (libraryEvent.snapshot.exists && libraryEvent.snapshot.value != null) {
        Map<dynamic, dynamic> libraryData = libraryEvent.snapshot.value as Map<dynamic, dynamic>;

        // Get book details for each book in library
        for (String bookId in libraryData.keys) {
          // Find the book in allBooks - use try/catch approach instead of orElse
          try {
            Book? book = allBooks.firstWhere((b) => b.id == bookId);
            libraryBooks.add(book);
          } catch (e) {
            // Book not found in allBooks, skip it
            print('Book with id $bookId not found in allBooks');
            continue;
          }
        }
      }

      if (!_disposed) { // Check if disposed before setState
        setState(() {
          userLibraryBooks = libraryBooks;
        });
      }

      print('Loaded ${libraryBooks.length} library books');
    } catch (e) {
      print('Error loading user library: $e');
    }
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

  // Navigate to book detail (you'll need to update this to work with Book)
  void _navigateToBookDetail(Book book) {
    // Convert Book to the format your BookDetail expects
    Map<String, String> bookData = {
      'id': book.id,
      'title': book.title,
      'author': book.authorId, // You might want to get the actual author name
      'description': book.description,
      'coverUrl': '', // You'll handle this in BookDetail
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetail(book: bookData),
      ),
    );
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
            onPressed: _loadData,
          ),
        ],
      ),
      body: SingleChildScrollView(
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

            // Author Section
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
                  return GestureDetector( // Add this GestureDetector
                    onTap: () {
                      // Navigate to author details page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AuthorDetailsPage(author: author),
                        ),
                      );
                    },
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

      // Bottom Nav Bar
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
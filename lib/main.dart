import 'package:flutter/material.dart';
import 'package:standard_searchbar/old/standard_searchbar.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InkFlow',

      // App theme
      theme: ThemeData(
        primaryColor: Colors.deepPurple,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          primary: Colors.deepPurple,
          secondary: Colors.deepPurpleAccent,
        ),

        // NavBar theme
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.deepPurple.shade100,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.deepPurple.shade300,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        ),

        // App font
        textTheme: GoogleFonts.cinzelTextTheme(),
      ),
      // Routes
      initialRoute: '/',
      routes: {
        // When navigating to the "/" route, build the HomeScreen widget.
        '/': (context) => HomeScreen(),
        // When navigating to the "/library" route, build the Library widget.
        '/library': (context) => Library(),
        '/book_detail': (context) => BookDetail(book: {},),
        '/all_books': (context) => Books(),
        '/all_authors': (context)=> Authors(),
      },
    );
  }
}
// sample data (temporary)
final List<Map<String, String>> books = [
  {
    "title": "The Hobbit",
    "author": "J.R.R. Tolkien",
    "coverUrl": "https://m.media-amazon.com/images/I/91b0C2YNSrL._AC_UF1000,1000_QL80_.jpg",
  },
  {
    "title": "1984",
    "author": "George Orwell",
    "coverUrl": "https://m.media-amazon.com/images/I/71kxa1-0mfL._AC_UF1000,1000_QL80_.jpg",
  },
  {
    "title": "The Catcher in the Rye",
    "author": "J.D. Salinger",
    "coverUrl": "https://m.media-amazon.com/images/I/81OthjkJBuL._AC_UF1000,1000_QL80_.jpg",
  },
  {
    "title": "To Kill a Mockingbird",
    "author": "Harper Lee",
    "coverUrl": "https://m.media-amazon.com/images/I/81gepf1eMqL._AC_UF1000,1000_QL80_.jpg",
  },
  {
    "title": "Harry Potter and the Sorcerer's Stone",
    "author": "J.K. Rowling",
    "coverUrl": "https://m.media-amazon.com/images/I/81YOuOGFCJL._AC_UF1000,1000_QL80_.jpg",
  },
];
final List<Map<String, dynamic>> authors = [
  {
    "name": "J.R.R. Tolkien",
    "profileUrl": "https://via.placeholder.com/150",
    "followers": 0,
    "likes": 0,
  },
  {
    "name": "George Orwell",
    "profileUrl": "https://via.placeholder.com/150",
    "followers": 0,
    "likes": 0,
  },
  {
    "name": "Jane Austen",
    "profileUrl": "https://via.placeholder.com/150",
    "followers": 0,
    "likes": 0,
  },
];
// HOME SCREEN
class HomeScreen extends StatelessWidget{
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:Text('Inkflow'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        automaticallyImplyLeading: true,
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
              child: ListView.builder(
                itemCount: books.length,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  final book = books[index];
                  return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookDetail(book: book),
                          ),
                        );
                      },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Book Cover
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            book["coverUrl"]!,
                            width: 150,
                            height: 200,
                            fit: BoxFit.fill,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 150,
                                height: 200,
                                color: Colors.grey.shade300,
                                child: Icon(Icons.image_not_supported, size: 40),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 5),
                        // Book Title
                        Container(
                          width: 150,
                          height: 35,
                          child: Text(
                            book["title"]!,
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
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: books.length,
                padding: EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  final book = books[index];
                  return Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect( // for rounded corners to make it look pretty
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            book["coverUrl"]!,
                            width: 100,
                            height: 120,
                            fit: BoxFit.fill,
                          ),
                        ),
                        SizedBox(height: 5),
                        Container(
                          width: 100,
                          child: Text(
                            book["title"]!,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
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
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: authors.length,
                padding: EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  final author = authors[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey.shade300,
                          child: Text(
                            author["name"].substring(0, 1),
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          author["name"],
                          style: TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Bottom Nav Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,  // Ensures labels are always visible
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_rounded), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.my_library_books_rounded), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: 0, // HomeScreen Index
        onTap: (index) {
          // Library Index, tapping on lib icon takes to library screen
          if (index == 2) {
            Navigator.pushNamed(context, '/library');
          }
        },
      ),
    );
  }
}

// LIBRARY PAGE
class Library extends StatelessWidget{
  const Library({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Library'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
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
              )
          ),
          Expanded(child:ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book cover
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        book["coverUrl"]!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.fill,
                      ),
                    ),
                    SizedBox(width: 16),
                    // Book details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book["title"]!,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            "By ${book["author"]!}",
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                          ),
                          SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          ),

        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,  // Ensures labels are always visible
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_rounded), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.my_library_books_rounded), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: 2, // Library Index
        onTap: (index) {
          // Home screen index
          if (index == 0) {
            Navigator.pushNamed(context, '/');
          }
        },
      ),
    );
  }
}
// BOOK DETAIL PAGE
class BookDetail extends StatefulWidget {
  final Map<String, String> book;

  const BookDetail({super.key, required this.book});

  @override
  _BookDetailState createState() => _BookDetailState();
}

class _BookDetailState extends State<BookDetail> {
  bool isLiked = false;
  bool isInLibrary = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.book["title"]!)),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Book Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.book["coverUrl"]!,
                width: 150,
                height: 200,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 150,
                    height: 200,
                    color: Colors.grey.shade300,
                    child: Icon(Icons.image_not_supported, size: 40),
                  );
                },
              ),
            ),
            SizedBox(height: 10),

            // Book Title & Author
            Text(widget.book["title"]!, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text("by ${widget.book["author"]!}", style: TextStyle(fontSize: 18, color: Colors.grey[700])),

            SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Read Button
                ElevatedButton.icon(
                  onPressed: () {
                    // will lead to screen with book chapters
                  },
                  icon: Icon(Icons.book),
                  label: Text("Read"),
                ),

                // Like Button
                IconButton(
                  onPressed: () {
                    setState(() {
                      isLiked = !isLiked;
                    });
                  },
                  icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : null),
                ),

                // Add to Library
                IconButton(
                  onPressed: () {
                    setState(() {
                      isInLibrary = !isInLibrary;
                    });
                  },
                  icon: Icon(isInLibrary ? Icons.check_circle : Icons.library_add, color: isInLibrary ? Colors.green : null),
                ),

                // Subscribe / Buy
                ElevatedButton.icon(
                  onPressed: () {
                  },
                  icon: Icon(Icons.shopping_cart),
                  label: Text("Buy"),
                ),


              ],
            ),
            SizedBox(height: 5,),
            Text('Description...'),
          ],
        ),
      ),
    );
  }
}

// BOOKS PAGE
class Books extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Books'),
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
        centerTitle: true,
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
              )
          ),
          Expanded(child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book cover
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        book["coverUrl"]!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.fill,
                      ),
                    ),
                    SizedBox(width: 16),
                    // Book details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book["title"]!,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            "By ${book["author"]!}",
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade700),
                          ),
                          SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          ),
        ],
      ),
    );
  }
}
// AUTHORS PAGE
class Authors extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Authors'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
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
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: authors.length,
              itemBuilder: (context, index) {
                final author = authors[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Author Profile Picture (Fixed Size)
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50), // Make it round
                          child: Image.network(
                            author["profileUrl"]!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey.shade300,
                                  child: Icon(Icons.person, size: 40, color: Colors.grey),
                                ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),

                      // Author Details (Flexible to prevent overflow)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              author["name"]!,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Followers: ${author["followers"]}",
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                            ),
                            Text(
                              "Likes: ${author["likes"]}",
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
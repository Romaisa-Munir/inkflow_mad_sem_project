import 'package:flutter/material.dart';
import 'package:standard_searchbar/old/standard_searchbar.dart';
import '../../data/sample_data.dart';
import '../writing_dashboard.dart';
import '../profile/profile_page.dart';
import '../books/book_detail.dart';

class HomeScreen extends StatefulWidget{
  @override
  HomeScreenState createState() =>HomeScreenState();
}
// HOME SCREEN
class HomeScreenState extends State<HomeScreen>{
  // For searching both books and authors
  List<Map<String, String>> filteredBooks = [];
  List<Map<String, dynamic>> filteredAuthors = [];

  @override
  void initState() {
    super.initState();
    filteredBooks = List.from(books);
    filteredAuthors = List.from(authors);
  }

  void searchAll(String query) {
    final lower = query.toLowerCase();
    setState(() {
      filteredBooks = books.where((book) =>
      book['title']!.toLowerCase().contains(lower) ||
          book['author']!.toLowerCase().contains(lower)
      ).toList();

      filteredAuthors = authors.where((author) =>
          author['name'].toLowerCase().contains(lower)
      ).toList();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:Text('Inkflow'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        automaticallyImplyLeading: false, // removes back arrow(not needed on home screen)
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
              child: ListView.builder(
                itemCount: filteredBooks.length,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  final book = filteredBooks[index];
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
                itemCount: filteredBooks.length,
                padding: EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  final book = filteredBooks[index];
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
                itemCount: filteredAuthors.length,
                padding: EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  final author = filteredAuthors[index];
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
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WritingDashboard()),
            );
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
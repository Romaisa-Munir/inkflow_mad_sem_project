import 'package:flutter/material.dart';
import 'package:standard_searchbar/old/standard_searchbar.dart';
import '../../data/sample_data.dart';
import '../writing_dashboard.dart';
import '../profile/profile_page.dart';
// LIBRARY PAGE
class Library extends StatefulWidget {
  @override
  _LibraryState createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  List<Map<String, String>> filteredBooks = [];

  @override
  void initState() {
    super.initState();
    // Initialize with all books
    filteredBooks = List.from(books);
  }

  void searchBooks(String query) {
    final lower = query.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        filteredBooks = List.from(books);
      });
      return;
    }
    // Filter books that contain the query in title or author
    setState(() {
      filteredBooks = books.where((book) {
        final titleMatch = book['title']?.toLowerCase().contains(lower) ?? false;
        final authorMatch = book['author']?.toLowerCase().contains(lower) ?? false;
        return titleMatch || authorMatch;
      }).toList();
    });
  }

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
                onChanged: searchBooks,
              )
          ),
          Expanded(
            child: filteredBooks.isEmpty
                ? Center(child: Text("No books found"))
                : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: filteredBooks.length,
              itemBuilder: (context, index) {
                final book = filteredBooks[index];
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
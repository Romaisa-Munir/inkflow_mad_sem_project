import 'package:flutter/material.dart';
import 'package:standard_searchbar/old/standard_searchbar.dart';
import '../../data/sample_data.dart';

class Books extends StatefulWidget{
  @override
  BooksState createState() =>BooksState();
}
class BooksState extends State<Books>{
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
      // If query is empty, show all books
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
                onChanged: searchBooks,
              )
          ),
          Expanded(child: ListView.builder(
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
import 'package:flutter/material.dart';
import 'package:standard_searchbar/old/standard_searchbar.dart';
import '../../data/sample_data.dart';
class Authors extends StatefulWidget {
  @override
  _AuthorsState createState() => _AuthorsState();
}

class _AuthorsState extends State<Authors> {
  List<Map<String, dynamic>> filteredAuthors = [];

  @override
  void initState() {
    super.initState();
    filteredAuthors = List.from(authors);
  }

  void searchAuthors(String query) {
    final lower = query.toLowerCase();
    setState(() {
      filteredAuthors = authors.where((author) =>
          author['name'].toLowerCase().contains(lower)
      ).toList();
    });
  }
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
              onChanged: searchAuthors,
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: filteredAuthors.length,
              itemBuilder: (context, index) {
                final author = filteredAuthors[index];;
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
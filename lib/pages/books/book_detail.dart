import 'package:flutter/material.dart';
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
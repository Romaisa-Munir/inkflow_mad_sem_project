import 'package:flutter/material.dart';

class ChapterCard extends StatelessWidget {
  final String title;
  final String content;
  final String price;
  final VoidCallback onTap;

  ChapterCard({
    required this.title,
    required this.content,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Tappable to edit the chapter
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                content.length > 100
                    ? content.substring(0, 100) + '...' // Truncate content
                    : content, // Display full content if it's short enough
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                'Price: \$${price}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

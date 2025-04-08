import 'dart:io';
import 'package:flutter/material.dart';
import '../models/book_model.dart';
import 'AddChapterPage.dart';
import '../widgets/chapter_card.dart';

class BookDetailsPage extends StatefulWidget {
  final Book book;

  BookDetailsPage({required this.book});

  @override
  _BookDetailsPageState createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  List<Map<String, String>> chapters = [];

  void _addChapter() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddChapterPage(
          onSave: (chapterTitle, chapterContent, chapterPrice) {
            setState(() {
              chapters.add({
                'title': chapterTitle,
                'content': chapterContent,
                'price': chapterPrice.toString(),
              });
            });
          },
        ),
      ),
    );
  }

  void _editChapter(int index) {
    var chapter = chapters[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddChapterPage(
          onSave: (chapterTitle, chapterContent, chapterPrice) {
            setState(() {
              chapters[index] = {
                'title': chapterTitle,
                'content': chapterContent,
                'price': chapterPrice.toString(),
              };
            });
          },
          initialTitle: chapter['title'],
          initialContent: chapter['content'],
          initialPrice: double.tryParse(chapter['price']!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            widget.book.coverUrl != null && widget.book.coverUrl!.isNotEmpty
                ? Image.file(
              File(widget.book.coverUrl!),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            )
                : Container(
              height: 200,
              color: Colors.grey[300],
              child: Icon(Icons.image, size: 50, color: Colors.grey[700]),
            ),
            SizedBox(height: 12),
            Text(
              widget.book.title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(widget.book.description),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addChapter,
              child: Text('Add Chapter'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: chapters.length,
                itemBuilder: (context, index) {
                  var chapter = chapters[index];
                  return ChapterCard(
                    title: chapter['title']!,
                    content: chapter['content']!,
                    price: chapter['price']!,
                    onTap: () {
                      _editChapter(index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

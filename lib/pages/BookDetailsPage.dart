import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/book_model.dart';
import '../models/chapter_model.dart'; // Your enhanced chapter model
import 'AddChapterPage.dart';
import '../widgets/chapter_card.dart';
import 'package:inkflow_mad_sem_project/pages/Analytics/book_analytics_page.dart'; // Add this import

class BookDetailsPage extends StatefulWidget {
  final Book book;

  BookDetailsPage({required this.book});

  @override
  _BookDetailsPageState createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  List<Chapter> chapters = [];
  bool _isLoading = true;
  bool _disposed = false;
  bool _isDescriptionExpanded = false; // Track if description is expanded

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _loadChapters() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get chapters from Firebase
      final DatabaseEvent event = await _database
          .child('users')
          .child(currentUser.uid)
          .child('books')
          .child(widget.book.id)
          .child('chapters')
          .once();

      if (event.snapshot.exists && event.snapshot.value != null) {
        final Map<dynamic, dynamic> chaptersData =
        event.snapshot.value as Map<dynamic, dynamic>;

        List<Chapter> loadedChapters = [];
        chaptersData.forEach((chapterId, chapterData) {
          if (chapterData != null) {
            try {
              Map<String, dynamic> chapterMap = Map<String, dynamic>.from(chapterData);
              Chapter chapter = Chapter.fromMap(chapterMap, chapterId);
              loadedChapters.add(chapter);
            } catch (e) {
              print('Error parsing chapter $chapterId: $e');
            }
          }
        });

        // Sort chapters by creation date (oldest first)
        loadedChapters.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        if (!_disposed) {
          setState(() {
            chapters = loadedChapters;
            _isLoading = false;
          });
        }
      } else {
        if (!_disposed) {
          setState(() {
            chapters = [];
            _isLoading = false;
          });
        }
      }

      print('Loaded ${chapters.length} chapters for book ${widget.book.title}');
    } catch (e) {
      print('Error loading chapters: $e');
      if (!_disposed) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading chapters: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addChapter() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddChapterPage(
          bookId: widget.book.id,
          onSave: (Chapter newChapter) {
            setState(() {
              chapters.add(newChapter);
              // Sort chapters by creation date
              chapters.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            });
          },
        ),
      ),
    );
  }

  void _editChapter(Chapter chapter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddChapterPage(
          bookId: widget.book.id,
          existingChapter: chapter,
          onSave: (Chapter updatedChapter) {
            setState(() {
              int index = chapters.indexWhere((c) => c.id == updatedChapter.id);
              if (index != -1) {
                chapters[index] = updatedChapter;
              }
            });
          },
        ),
      ),
    );
  }

  void _openBookAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookAnalyticsPage(
          book: widget.book,
        ),
      ),
    );
  }

  Future<void> _deleteChapter(Chapter chapter) async {
    // Show confirmation dialog
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Chapter'),
        content: Text('Are you sure you want to delete "${chapter.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        final User? currentUser = _auth.currentUser;
        if (currentUser == null) return;

        // Delete from Firebase
        await _database
            .child('users')
            .child(currentUser.uid)
            .child('books')
            .child(widget.book.id)
            .child('chapters')
            .child(chapter.id)
            .remove();

        // Remove from local list
        setState(() {
          chapters.removeWhere((c) => c.id == chapter.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chapter deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting chapter: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteBook() async {
    // Show confirmation dialog
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Book'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${widget.book.title}"?'),
            SizedBox(height: 10),
            Text(
              'This will permanently delete:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Text('• The entire book'),
            Text('• All ${chapters.length} chapters'),
            Text('• All associated data'),
            SizedBox(height: 10),
            Text(
              'This action cannot be undone!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete Forever',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        final User? currentUser = _auth.currentUser;
        if (currentUser == null) return;

        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Deleting book...'),
              ],
            ),
          ),
        );

        // Delete the entire book (including all chapters) from Firebase
        await _database
            .child('users')
            .child(currentUser.uid)
            .child('books')
            .child(widget.book.id)
            .remove();

        // Also remove from user's library if it exists
        await _database
            .child('users')
            .child(currentUser.uid)
            .child('library')
            .child(widget.book.id)
            .remove();

        // Close loading dialog
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Book deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to previous screen
        Navigator.pop(context, true); // Return true to indicate book was deleted

      } catch (e) {
        // Close loading dialog if it's open
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting book: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildBookCover() {
    if (widget.book.coverImage != null && widget.book.coverImage!.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(widget.book.coverImage!),
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultCover();
          },
        );
      } catch (e) {
        return _buildDefaultCover();
      }
    }
    return _buildDefaultCover();
  }

  Widget _buildDefaultCover() {
    return Container(
      height: 200,
      color: Colors.grey[300],
      child: Icon(Icons.book, size: 50, color: Colors.grey[700]),
    );
  }

  // Build description with expand/collapse functionality
  Widget _buildDescription() {
    final description = widget.book.description;
    final isLongDescription = description.length > 200; // Show "Read more" for descriptions over 200 characters

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          child: Text(
            _isDescriptionExpanded || !isLongDescription
                ? description
                : '${description.substring(0, 200)}...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
            textAlign: TextAlign.center,
            softWrap: true,
          ),
        ),
        if (isLongDescription) ...[
          SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _isDescriptionExpanded = !_isDescriptionExpanded;
                });
              },
              child: Text(
                _isDescriptionExpanded ? 'Show Less' : 'Read More',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Analytics button
          IconButton(
            icon: Icon(Icons.analytics, color: Colors.blue),
            onPressed: _openBookAnalytics,
            tooltip: 'Book Analytics',
          ),
          // Delete Book button
          IconButton(
            icon: Icon(Icons.delete_forever, color: Colors.red),
            onPressed: _deleteBook,
            tooltip: 'Delete Book',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadChapters();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView( // Wrap in SingleChildScrollView to prevent overflow
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Book cover
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildBookCover(),
            ),
            SizedBox(height: 12),

            // Book title
            Text(
              widget.book.title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),

            // Book description with expand/collapse functionality
            _buildDescription(),
            SizedBox(height: 20),

            // Add Chapter button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addChapter,
                icon: Icon(Icons.add),
                label: Text('Add Chapter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Chapters section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chapters (${chapters.length})',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 10),

            // Chapters list - Use a fixed height container instead of Expanded
            Container(
              height: 300, // Fixed height for chapters section
              child: chapters.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.library_books_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No chapters yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add your first chapter to get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: chapters.length,
                itemBuilder: (context, index) {
                  final chapter = chapters[index];
                  return ChapterCard(
                    title: chapter.title,
                    content: chapter.content,
                    price: chapter.price.toString(),
                    onTap: () => _editChapter(chapter),
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
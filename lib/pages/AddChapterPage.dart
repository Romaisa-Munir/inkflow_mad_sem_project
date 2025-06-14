import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/chapter_model.dart';

class AddChapterPage extends StatefulWidget {
  final String bookId;
  final Chapter? existingChapter; // For editing
  final Function(Chapter) onSave;

  AddChapterPage({
    required this.bookId,
    required this.onSave,
    this.existingChapter,
  });

  @override
  _AddChapterPageState createState() => _AddChapterPageState();
}

class _AddChapterPageState extends State<AddChapterPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _priceController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // If editing existing chapter, populate fields
    if (widget.existingChapter != null) {
      _titleController.text = widget.existingChapter!.title;
      _contentController.text = widget.existingChapter!.content;
      _priceController.text = widget.existingChapter!.price.toString();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _priceController.dispose();
    super.dispose();
  }
  Future<void> _saveChapter() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final String title = _titleController.text.trim();
      final String content = _contentController.text.trim();
      final double price = double.parse(_priceController.text.trim());

      Chapter chapter;

      if (widget.existingChapter != null) {
        // Editing existing chapter - keep the same order
        chapter = widget.existingChapter!.copyWith(
          title: title,
          content: content,
          price: price,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        // Update in Firebase
        await _database
            .child('users')
            .child(currentUser.uid)
            .child('books')
            .child(widget.bookId)
            .child('chapters')
            .child(chapter.id)
            .update(chapter.toMap());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chapter updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Adding new chapter - get the next order number
        final String chapterId = _database
            .child('users')
            .child(currentUser.uid)
            .child('books')
            .child(widget.bookId)
            .child('chapters')
            .push()
            .key!;

        chapter = Chapter(
          id: chapterId,
          title: title,
          content: content,
          price: price,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        // Just use the chapter data without manual order field
        // Let the sorting logic use createdAt instead
        Map<String, dynamic> chapterData = chapter.toMap();

        // Save to Firebase
        await _database
            .child('users')
            .child(currentUser.uid)
            .child('books')
            .child(widget.bookId)
            .child('chapters')
            .child(chapterId)
            .set(chapterData);

        print('Created chapter "$title" with createdAt: ${DateTime.now().millisecondsSinceEpoch}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chapter added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Call the callback to update the parent page
      widget.onSave(chapter);

      // Return to previous page
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving chapter: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _getWordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.existingChapter != null;
    final int wordCount = _getWordCount(_contentController.text);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Chapter' : 'Add Chapter'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Chapter Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a chapter title';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Word count display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chapter Content',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '$wordCount / 4000 words',
                      style: TextStyle(
                        fontSize: 12,
                        color: wordCount > 4000 ? Colors.red : Colors.grey[600],
                        fontWeight: wordCount > 4000 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                Container(
                  height: 200, // Fixed height to prevent overflow
                  child: TextFormField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      hintText: 'Write your chapter content here...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                      contentPadding: EdgeInsets.all(12),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter chapter content';
                      }
                      final wordCount = _getWordCount(value);
                      if (wordCount > 4000) {
                        return 'Chapter content cannot exceed 4000 words (current: $wordCount words)';
                      }
                      return null;
                    },
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    onChanged: (value) {
                      setState(() {
                        // Trigger rebuild to update word count
                      });
                    },
                  ),
                ),

                if (wordCount > 4000)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Warning: Chapter exceeds 4000 word limit',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'Chapter Price (\$)',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a price';
                    }
                    final double? price = double.tryParse(value.trim());
                    if (price == null || price < 0) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveChapter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                    ),
                    child: _isLoading
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(isEditing ? 'Updating...' : 'Saving...'),
                      ],
                    )
                        : Text(
                      isEditing ? 'Update Chapter' : 'Save Chapter',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(height: 20), // Extra space at bottom
              ],
            ),
          ),
        ),
      ),
    );
  }
}
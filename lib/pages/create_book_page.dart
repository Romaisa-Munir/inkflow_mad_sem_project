import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book_model.dart';
import '../services/author_service.dart';
import '../services/ai_service.dart';

class CreateBookPage extends StatefulWidget {
  @override
  _CreateBookPageState createState() => _CreateBookPageState();
}

class _CreateBookPageState extends State<CreateBookPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _titleController = TextEditingController();
  String _title = '';
  String _description = '';
  File? _coverImage;
  bool _isLoading = false;
  int _descriptionWordCount = 0;
  List<String> _suggestedTitles = [];
  bool _isGeneratingTitles = false;

  final ImagePicker _picker = ImagePicker();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Listen to description changes
    _descriptionController.addListener(() {
      setState(() {
        _descriptionWordCount = _countWords(_descriptionController.text);
        _description = _descriptionController.text;
      });
    });

    // Add listener for title controller
    _titleController.addListener(() {
      setState(() {
        _title = _titleController.text;
      });
    });
  }

  // Helper function to count words
  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _generateTitles() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a book description first')),
      );
      return;
    }

    setState(() {
      _isGeneratingTitles = true;
      _suggestedTitles = [];
    });

    try {
      final titles = await AIService.generateBookTitles(_descriptionController.text);
      setState(() {
        _suggestedTitles = titles;
      });

      if (titles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate titles. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate titles: $e')),
      );
    } finally {
      setState(() {
        _isGeneratingTitles = false;
      });
    }
  }

  Future<void> _pickCoverImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _coverImage = File(image.path);
      });
    }
  }

  Future<void> _updateUserAuthorStatus() async {
    try {
      final String userId = _auth.currentUser!.uid;

      await _database.child('users/$userId').update({
        'isAuthor': true,
        'lastActive': DateTime.now().millisecondsSinceEpoch,
      });

      await _database.child('users/$userId/profile/role').set('writer');

      print('Updated user author status for user: $userId');
    } catch (e) {
      print('Error updating user author status: $e');
    }
  }

  Future<String?> _convertImageToBase64() async {
    if (_coverImage == null) return null;

    try {
      final bytes = await _coverImage!.readAsBytes();
      final base64String = base64Encode(bytes);
      return base64String;
    } catch (e) {
      print('Error converting image to base64: $e');
      return null;
    }
  }

  Future<void> _updateUserRole() async {
    try {
      final String userId = _auth.currentUser!.uid;
      await _database.child('users/$userId/profile/role').set('writer');
    } catch (e) {
      print('Error updating user role: $e');
    }
  }

  Future<void> _createBooksCollectionIfNeeded() async {
    try {
      final String userId = _auth.currentUser!.uid;
      final DatabaseEvent event = await _database.child('users/$userId/books').once();

      if (!event.snapshot.exists) {
        await _database.child('users/$userId/books').set({});
      }
    } catch (e) {
      print('Error creating books collection: $e');
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final String userId = _auth.currentUser!.uid;

        await _createBooksCollectionIfNeeded();

        final String bookId = _database.child('users/$userId/books').push().key!;

        String? coverBase64;
        if (_coverImage != null) {
          coverBase64 = await _convertImageToBase64();
        }

        final Map<String, dynamic> bookData = {
          'id': bookId,
          'title': _title,
          'description': _description,
          'coverImage': coverBase64,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'authorId': userId,
          'status': 'draft',
        };

        await _database.child('users/$userId/books/$bookId').set(bookData);

        await _updateUserRole();
        await AuthorService.onBookCreated(bookId);

        final newBook = Book(
          id: bookId,
          title: _title,
          description: _description,
          coverImage: coverBase64,
          authorId: userId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        await _updateUserAuthorStatus();

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Book created successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pop(context, newBook);

      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating book: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        print('Detailed error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create New Book"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      resizeToAvoidBottomInset: true,
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            SizedBox(height: 16),
            Text(
              'Creating your book...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Book Title',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter book title or use AI suggestions below',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Title must be at least 2 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$_descriptionWordCount/2000 words',
                    style: TextStyle(
                      fontSize: 12,
                      color: _descriptionWordCount > 2000 ? Colors.red : Colors.grey[600],
                      fontWeight: _descriptionWordCount > 2000 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Container(
                constraints: BoxConstraints(
                  maxHeight: 200,
                ),
                child: TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Enter book description (max 2000 words)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    counterText: '',
                  ),
                  maxLines: null,
                  minLines: 4,
                  textAlignVertical: TextAlignVertical.top,
                  expands: false,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Description is required';
                    }
                    if (value.trim().length < 10) {
                      return 'Description must be at least 10 characters';
                    }
                    int wordCount = _countWords(value);
                    if (wordCount > 2000) {
                      return 'Description cannot exceed 2000 words (currently $wordCount words)';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 20),

              // AI Title Generation Button
              ElevatedButton.icon(
                onPressed: _isGeneratingTitles ? null : _generateTitles,
                icon: _isGeneratingTitles
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : Icon(Icons.auto_awesome, color: Colors.white),
                label: Text(
                  _isGeneratingTitles ? 'Generating AI Titles...' : 'Generate AI Title Suggestions',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),

              // AI Suggestions Display
              if (_suggestedTitles.isNotEmpty) ...[
                SizedBox(height: 20),
                Text(
                  '✨ AI Suggested Titles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.withOpacity(0.2)),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Column(
                    children: _suggestedTitles.asMap().entries.map((entry) {
                      final index = entry.key;
                      final title = entry.value;
                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        child: Material(
                          elevation: 1,
                          borderRadius: BorderRadius.circular(8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.purple,
                              radius: 16,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            title: Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.purple,
                            ),
                            onTap: () {
                              setState(() {
                                _titleController.text = title;
                                _title = title;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white),
                                      SizedBox(width: 8),
                                      Expanded(child: Text('Title selected: $title')),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap any title above to use it for your book',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              SizedBox(height: 20),
              Text(
                'Cover Image (Optional)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _coverImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _coverImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
                    : Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image,
                        size: 50,
                        color: Colors.grey[600],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No image selected',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickCoverImage,
                      icon: Icon(Icons.photo_library),
                      label: Text("Pick Cover Image"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (_coverImage != null) ...[
                    SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _coverImage = null;
                        });
                      },
                      icon: Icon(Icons.clear),
                      label: Text("Remove"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 40),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Create Book",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
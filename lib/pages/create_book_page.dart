import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book_model.dart';

class CreateBookPage extends StatefulWidget {
  @override
  _CreateBookPageState createState() => _CreateBookPageState();
}

class _CreateBookPageState extends State<CreateBookPage> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  File? _coverImage;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _pickCoverImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _coverImage = File(image.path);
      });
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

      // If books collection doesn't exist, create it with initial structure
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

        // Ensure books collection exists under user
        await _createBooksCollectionIfNeeded();

        // Generate unique book ID
        final String bookId = _database.child('users/$userId/books').push().key!;

        // Convert cover image to base64 if selected
        String? coverBase64;
        if (_coverImage != null) {
          coverBase64 = await _convertImageToBase64();
        }

        // Create book data structure
        final Map<String, dynamic> bookData = {
          'id': bookId,
          'title': _title,
          'description': _description,
          'coverImage': coverBase64, // Store as base64 string
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'authorId': userId,
          'status': 'draft', // Can be 'draft', 'published', etc.
        };

        // Save book to database under users/{userId}/books/{bookId}
        await _database.child('users/$userId/books/$bookId').set(bookData);

        // Update user role to writer
        await _updateUserRole();

        // Create Book object for return (you'll need to create this model)
        final newBook = Book(
          id: bookId,
          title: _title,
          description: _description,
          coverImage: coverBase64,
          authorId: userId,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        setState(() {
          _isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Book created successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back with the new book
        Navigator.pop(context, newBook);

      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        // Show error message
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
                decoration: InputDecoration(
                  hintText: 'Enter book title',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (value) => _title = value,
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
              Text(
                'Description',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'Enter book description',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                maxLines: 4,
                onChanged: (value) => _description = value,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  if (value.trim().length < 10) {
                    return 'Description must be at least 10 characters';
                  }
                  return null;
                },
              ),
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
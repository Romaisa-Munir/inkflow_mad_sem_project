import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/book_model.dart';

class CreateBookPage extends StatefulWidget {
  @override
  _CreateBookPageState createState() => _CreateBookPageState();
}

class _CreateBookPageState extends State<CreateBookPage> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  File? _coverImage; // Selected image from gallery

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickCoverImage() async {
    final XFile? image =
    await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _coverImage = File(image.path);
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Pass the image file's path as coverUrl if an image was selected
      final newBook = Book(
        title: _title,
        description: _description,
        coverUrl: _coverImage?.path,
      );
      Navigator.pop(context, newBook); // Return the new book to dashboard
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
      body: SingleChildScrollView(
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
              TextFormField(
                decoration: InputDecoration(hintText: 'Enter book title'),
                onChanged: (value) => _title = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Text(
                'Description',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextFormField(
                decoration: InputDecoration(hintText: 'Enter book description'),
                onChanged: (value) => _description = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Description is required';
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
              _coverImage != null
                  ? Image.file(
                _coverImage!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              )
                  : Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey[300],
                child: Icon(Icons.image, size: 50, color: Colors.grey[700]),
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _pickCoverImage,
                icon: Icon(Icons.photo_library),
                label: Text("Pick Cover Image"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              SizedBox(height: 30), // replaces Spacer()
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: Text("Create Book", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
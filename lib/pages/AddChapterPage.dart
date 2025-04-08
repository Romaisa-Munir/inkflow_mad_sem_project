import 'package:flutter/material.dart';

class AddChapterPage extends StatefulWidget {
  final Function(String, String, double) onSave;
  final String? initialTitle;
  final String? initialContent;
  final double? initialPrice;

  AddChapterPage({
    required this.onSave,
    this.initialTitle,
    this.initialContent,
    this.initialPrice,
  });

  @override
  _AddChapterPageState createState() => _AddChapterPageState();
}

class _AddChapterPageState extends State<AddChapterPage> {
  final _formKey = GlobalKey<FormState>();
  late String _chapterTitle;
  late String _chapterContent;
  late double _chapterPrice;

  @override
  void initState() {
    super.initState();
    // Initialize the fields with existing data if available (for editing)
    _chapterTitle = widget.initialTitle ?? '';
    _chapterContent = widget.initialContent ?? '';
    _chapterPrice = widget.initialPrice ?? 0.0;
  }

  void _saveChapter() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(_chapterTitle, _chapterContent, _chapterPrice);
      Navigator.pop(context); // Return to the Book Details page
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialTitle == null ? 'Add Chapter' : 'Edit Chapter'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _chapterTitle,
                decoration: InputDecoration(labelText: 'Chapter Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                onChanged: (value) => _chapterTitle = value,
              ),
              TextFormField(
                initialValue: _chapterContent,
                decoration: InputDecoration(labelText: 'Chapter Content'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter content';
                  }
                  return null;
                },
                onChanged: (value) => _chapterContent = value,
                maxLines: 5,
              ),
              // Always show price field for both adding and editing chapters
              TextFormField(
                initialValue: _chapterPrice.toString(),
                decoration: InputDecoration(labelText: 'Chapter Price'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  return null;
                },
                onChanged: (value) {
                  _chapterPrice = double.tryParse(value) ?? 0.0;
                },
              ),
              ElevatedButton(
                onPressed: _saveChapter,
                child: Text(widget.initialTitle == null ? 'Save Chapter' : 'Update Chapter'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class EditProfileDialog extends StatefulWidget {
  final String username;
  final String description;

  EditProfileDialog({required this.username, required this.description});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _usernameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username);
    _descriptionController = TextEditingController(text: widget.description);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit Profile"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: "About You"),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, {
              'username': _usernameController.text,
              'description': _descriptionController.text,
            });
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}

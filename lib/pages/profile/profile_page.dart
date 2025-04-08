import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../writing_dashboard.dart';
import 'settings_page.dart'; // Import the SettingsPage

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _profileImage;
  String _username = 'Your Username';
  String _description = 'Write something about yourself...';
  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  void _editUsername() {
    TextEditingController controller = TextEditingController(text: _username);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Username"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _username = controller.text);
              Navigator.pop(context);
            },
            child: Text("Save"),
          )
        ],
      ),
    );
  }

  void _editDescription() {
    TextEditingController controller = TextEditingController(text: _description);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Description"),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _description = controller.text);
              Navigator.pop(context);
            },
            child: Text("Save"),
          )
        ],
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : AssetImage('assets/profile.jpeg'),
              ),
            ),
            SizedBox(height: 12),
            Text(
              _username,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: _editUsername,
              child: Text("Edit Username"),
            ),
            SizedBox(height: 12),
            Text(
              _description,
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: _editDescription,
              child: Text("Edit Description"),
            ),
            Divider(height: 40),
            Text(
              'Books will be added here dynamically with database integration.',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,  // Ensures labels are always visible
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_rounded), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.my_library_books_rounded), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: 3, // Profile Index
        onTap: (index) {
          // Home screen index
          if (index == 0) {
            Navigator.pushNamed(context, '/');
          }
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WritingDashboard()),
            );
          }
          if (index == 2) {
            Navigator.pushNamed(context, '/library');
          }

        },
      ),
    );
  }
}

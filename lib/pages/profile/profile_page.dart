import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
// Add this dependency to pubspec.yaml: image: ^4.0.17
import 'package:image/image.dart' as img;
import '../writing_dashboard.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _profileImage;
  String _username = '';
  String _description = '';
  String _role = 'reader';
  List<Map<String, dynamic>> _writtenBooks = [];
  bool _isLoading = true;
  bool _isUploadingImage = false;
  String? _profileImageBase64;

  final picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This ensures the check runs every time the page is navigated to
    if (mounted) {
      _performBookCheckAndRoleUpdate();
    }
  }

  // Refresh profile when returning from other screens
  void _refreshProfile() {
    setState(() {
      _isLoading = true;
    });
    _loadUserProfile();
    // Also perform book check when manually refreshing
    _performBookCheckAndRoleUpdate();
  }

  // Dedicated method to check books and update role - called every time page is navigated to
  Future<void> _performBookCheckAndRoleUpdate() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      print('=== PERFORMING BOOK CHECK ON PROFILE NAVIGATION ===');

      // Check for books in user's collection
      DatabaseEvent booksEvent = await _database.child('users/${currentUser.uid}/books').once();
      DataSnapshot booksSnapshot = booksEvent.snapshot;

      bool hasBooks = false;
      Map<dynamic, dynamic>? booksMap;

      if (booksSnapshot.exists && booksSnapshot.value != null) {
        booksMap = booksSnapshot.value as Map<dynamic, dynamic>;
        hasBooks = booksMap.isNotEmpty;
      }

      // Determine and update role
      String newRole = hasBooks ? 'writer' : 'reader';

      print('Books found: $hasBooks, Setting role to: $newRole');

      // Always update role in Firebase to ensure consistency
      await _database.child('users/${currentUser.uid}/profile/role').set(newRole);

      // Update state
      setState(() {
        _role = newRole;
      });

      // Load and display books if user has any
      if (hasBooks && booksMap != null) {
        await _loadWrittenBooksFromUserBooks(booksMap);
      } else {
        setState(() {
          _writtenBooks = [];
        });
      }

      print('=== BOOK CHECK COMPLETED: Role=$_role, Books=${_writtenBooks.length} ===');

    } catch (e) {
      print('Error in book check and role update: $e');
    }
  }

  // Load user profile data from Firebase
  Future<void> _loadUserProfile() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get user data from Realtime Database
      DatabaseEvent event = await _database.child('users/${currentUser.uid}').once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.exists) {
        Map<dynamic, dynamic> userData = snapshot.value as Map<dynamic, dynamic>;
        await _processExistingUserData(userData, currentUser.uid);
      } else {
        // Create initial user profile if doesn't exist
        await _createInitialProfile(currentUser);
      }

      // Always check and update role after loading profile data
      await _checkAndUpdateUserRole();
      // Additional book check to ensure we catch any changes
      await _performBookCheckAndRoleUpdate();
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to load profile');
    }
  }

  // Process existing user data
  Future<void> _processExistingUserData(Map<dynamic, dynamic> userData, String uid) async {
    try {
      // Get current data
      String currentUsername = userData['profile']?['username'] ?? 'Your Username';
      String currentBio = userData['profile']?['bio'] ?? 'Write something about yourself...';
      String? currentProfileImage = userData['profile']?['profilePicBase64'];
      String currentRole = userData['profile']?['role'] ?? userData['role'] ?? 'reader';

      // Clean up old root level role if it exists and move to profile
      if (userData['role'] != null && userData['profile']?['role'] == null) {
        await _database.child('users/$uid/profile/role').set(userData['role']);
        await _database.child('users/$uid/role').remove();
        print('Migrated role from root to profile');
      }

      // Update state with current data
      setState(() {
        _username = currentUsername;
        _description = currentBio;
        _role = currentRole;
        _profileImageBase64 = currentProfileImage;
      });
    } catch (e) {
      print('Error processing user data: $e');
    }
  }

  // Create initial user profile
  Future<void> _createInitialProfile(User currentUser) async {
    try {
      Map<String, dynamic> initialProfile = {
        'email': currentUser.email ?? '',
        'createdAt': DateTime.now().toIso8601String(),
        'lastLogin': DateTime.now().toIso8601String(),
        'profile': {
          'username': 'Your Username',
          'bio': 'Write something about yourself...',
          'profilePicBase64': null,
          'role': 'reader', // Default role is reader
        },
        'paymentInfo': {
          'bankAccountNumber': '',
          'jazzCashNumber': '',
          'easyPaisaNumber': '',
          'ibanNumber': '',
        },
        'writtenBooks': {}, // Keep for backward compatibility if needed
        'books': {}, // This is where actual books are stored
        'library': {},
      };

      await _database.child('users/${currentUser.uid}').set(initialProfile);

      setState(() {
        _username = 'Your Username';
        _description = 'Write something about yourself...';
        _role = 'reader';
        _writtenBooks = [];
      });

      print('Initial profile created with role: reader');
    } catch (e) {
      print('Error creating profile: $e');
      _showErrorDialog('Failed to create profile');
    }
  }

  // Check and update user role based on written books - Called every time profile is loaded
  Future<void> _checkAndUpdateUserRole() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('Checking user role...');

      // Get current books from Firebase (matching WritingDashboard structure)
      DatabaseEvent booksEvent = await _database.child('users/${currentUser.uid}/books').once();
      DataSnapshot booksSnapshot = booksEvent.snapshot;

      // Check if user has any books
      bool hasWrittenBooks = false;
      Map<dynamic, dynamic>? booksMap;

      if (booksSnapshot.exists && booksSnapshot.value != null) {
        booksMap = booksSnapshot.value as Map<dynamic, dynamic>;
        hasWrittenBooks = booksMap.isNotEmpty;
      }

      // Determine correct role
      String correctRole = hasWrittenBooks ? 'writer' : 'reader';

      print('User has books: $hasWrittenBooks, Current role: $_role, Correct role: $correctRole');

      // Update role in Firebase and state if it has changed
      if (_role != correctRole) {
        await _database.child('users/${currentUser.uid}/profile/role').set(correctRole);
        setState(() {
          _role = correctRole;
        });
        print('Role updated from $_role to $correctRole');
      }

      // Load written books if user is a writer
      if (hasWrittenBooks && booksMap != null) {
        await _loadWrittenBooksFromUserBooks(booksMap);
      } else {
        setState(() {
          _writtenBooks = [];
        });
      }

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      print('Error checking/updating role: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load written books from user/books collection (matching WritingDashboard structure and Book model)
  Future<void> _loadWrittenBooksFromUserBooks(Map<dynamic, dynamic> booksMap) async {
    try {
      List<Map<String, dynamic>> books = [];

      print('Loading ${booksMap.length} books from user collection...');

      booksMap.forEach((key, value) {
        if (value != null) {
          Map<String, dynamic> bookData = Map<String, dynamic>.from(value);

          // Create book object matching the Book model structure
          Map<String, dynamic> book = {
            'id': bookData['id'] ?? key,
            'title': bookData['title'] ?? 'Untitled',
            'description': bookData['description'] ?? 'No description',
            'coverImage': bookData['coverImage'], // base64 string or null (matches Book model)
            'authorId': bookData['authorId'] ?? '',
            'createdAt': bookData['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
            'status': bookData['status'] ?? 'draft',
          };

          books.add(book);
          print('Loaded book: ${book['title']} (ID: ${book['id']})');
        }
      });

      // Sort books by creation date (newest first)
      books.sort((a, b) {
        int aTime = a['createdAt'] ?? 0;
        int bTime = b['createdAt'] ?? 0;
        return bTime.compareTo(aTime);
      });

      setState(() {
        _writtenBooks = books;
      });

      print('Successfully loaded ${books.length} books');
    } catch (e) {
      print('Error loading books from user collection: $e');
      setState(() {
        _writtenBooks = [];
      });
    }
  }

  // Public method to check and update role (can be called from other screens)
  Future<void> checkAndUpdateRole() async {
    await _checkAndUpdateUserRole();
  }

  // Helper method to get book cover image provider (updated for Book model)
  ImageProvider _getBookCoverImageProvider(Map<String, dynamic> book) {
    // Check if coverImage (base64 string) exists
    if (book['coverImage'] != null && book['coverImage'].isNotEmpty) {
      try {
        Uint8List bytes = base64Decode(book['coverImage']);
        return MemoryImage(bytes);
      } catch (e) {
        print('Error decoding book cover base64: $e');
      }
    }

    // Default book icon - you can change this to your preferred asset
    return AssetImage('assets/profile.jpeg'); // Using existing asset as fallback
  }

  // Compress and resize image
  Future<Uint8List> _compressImage(File imageFile) async {
    // Read the image file
    Uint8List imageBytes = await imageFile.readAsBytes();

    // Decode the image
    img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) throw Exception('Failed to decode image');

    // Resize the image (max 300x300 for profile pictures)
    img.Image resizedImage = img.copyResize(
      originalImage,
      width: 300,
      height: 300,
      interpolation: img.Interpolation.average,
    );

    // Encode as JPEG with quality compression (70% quality)
    List<int> compressedBytes = img.encodeJpg(resizedImage, quality: 70);

    return Uint8List.fromList(compressedBytes);
  }

  // Pick and convert image to base64
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
        _isUploadingImage = true;
      });

      await _convertAndUploadImage();
    }
  }

  // Convert image to base64 and save to Firebase
  Future<void> _convertAndUploadImage() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null && _profileImage != null) {
        // Compress the image first
        Uint8List compressedImageBytes = await _compressImage(_profileImage!);

        // Check if compressed image is still too large (limit to 500KB)
        if (compressedImageBytes.length > 500 * 1024) {
          throw Exception('Image is too large. Please select a smaller image.');
        }

        // Convert to base64
        String base64Image = base64Encode(compressedImageBytes);

        // Update profile image base64 in database
        await _database.child('users/${currentUser.uid}/profile/profilePicBase64').set(base64Image);

        setState(() {
          _profileImageBase64 = base64Image;
          _isUploadingImage = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile image updated successfully')),
          );
        }
      }
    } catch (e) {
      print('Error uploading image: $e');
      setState(() {
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: ${e.toString()}')),
        );
      }
    }
  }

  // Helper method to get image provider
  ImageProvider _getProfileImageProvider() {
    if (_profileImage != null && !_isUploadingImage) {
      return FileImage(_profileImage!);
    } else if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
      try {
        Uint8List bytes = base64Decode(_profileImageBase64!);
        return MemoryImage(bytes);
      } catch (e) {
        print('Error decoding profile image: $e');
        return AssetImage('assets/profile.jpeg');
      }
    } else {
      return AssetImage('assets/profile.jpeg');
    }
  }

  // Edit username
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
            labelText: 'Username',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              String newUsername = controller.text.trim();
              if (newUsername.isNotEmpty) {
                await _updateUsername(newUsername);
                Navigator.pop(context);
              }
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  // Update username in Firebase
  Future<void> _updateUsername(String newUsername) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _database.child('users/${currentUser.uid}/profile/username').set(newUsername);
        setState(() {
          _username = newUsername;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Username updated successfully')),
          );
        }
      }
    } catch (e) {
      print('Error updating username: $e');
      _showErrorDialog('Failed to update username');
    }
  }

  // Edit description/bio
  void _editDescription() {
    TextEditingController controller = TextEditingController(text: _description);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Bio"),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Bio',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              String newDescription = controller.text.trim();
              if (newDescription.isNotEmpty) {
                await _updateDescription(newDescription);
                Navigator.pop(context);
              }
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  // Update description/bio in Firebase
  Future<void> _updateDescription(String newDescription) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _database.child('users/${currentUser.uid}/profile/bio').set(newDescription);
        setState(() {
          _description = newDescription;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Bio updated successfully')),
          );
        }
      }
    } catch (e) {
      print('Error updating bio: $e');
      _showErrorDialog('Failed to update bio');
    }
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Profile"),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
            // Profile Picture
            GestureDetector(
              onTap: _isUploadingImage ? null : _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _getProfileImageProvider(),
                    child: _isUploadingImage
                        ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isUploadingImage ? Colors.grey : Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isUploadingImage ? Icons.hourglass_empty : Icons.camera_alt,
                        size: 24,
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),

            // Username
            Text(
              _username,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: _editUsername,
              child: Text("Edit Username"),
            ),
            SizedBox(height: 12),

            // Bio/Description
            Text(
              _description,
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: _editDescription,
              child: Text("Edit Bio"),
            ),

            // Role Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _role == 'writer' ? Colors.green : Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _role.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),

            Divider(height: 40),

            // Written Books Section
            if (_role == 'writer' && _writtenBooks.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'My Books (${_writtenBooks.length})',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _writtenBooks.length,
                itemBuilder: (context, index) {
                  final book = _writtenBooks[index];
                  return Card(
                    elevation: 4,
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                              child: Image(
                                image: _getBookCoverImageProvider(book),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: Icon(
                                      Icons.book,
                                      size: 50,
                                      color: Colors.grey[600],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            book['title'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ] else if (_role == 'writer' && _writtenBooks.isEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'My Books',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'No books published yet',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Text(
                'Create your first book to become a writer!',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_rounded), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.my_library_books_rounded), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamed(context, '/');
          }
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WritingDashboard()),
            ).then((result) {
              print('Returned from WritingDashboard with result: $result');

              if (result == true) {
                print('Book was created, refreshing profile...');
                // Perform immediate book check when returning from book creation
                _performBookCheckAndRoleUpdate();
                _refreshProfile();
              } else {
                print('No book created, but still checking role on return');
                // Always check for books when returning, regardless of result
                _performBookCheckAndRoleUpdate();
              }
            });
          }
          if (index == 2) {
            Navigator.pushNamed(context, '/library');
          }
        },
      ),
    );
  }
}
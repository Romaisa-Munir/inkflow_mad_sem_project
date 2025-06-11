import 'package:flutter/material.dart';
import 'package:standard_searchbar/old/standard_searchbar.dart';
import 'dart:convert';
import '../../models/author_model.dart';
import '../../services/author_service.dart';
import '../writing_dashboard.dart';
import '../profile/profile_page.dart';

class Authors extends StatefulWidget {
  @override
  _AuthorsState createState() => _AuthorsState();
}

class _AuthorsState extends State<Authors> {
  List<AuthorModel> allAuthors = [];
  List<AuthorModel> filteredAuthors = [];
  bool _isLoading = true;
  bool _disposed = false; // Add disposal flag
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAuthors();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _fetchAuthors() async {
    if (_disposed) return; // Check if disposed

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final List<AuthorModel> authors = await AuthorService.fetchAuthors();

      if (!_disposed) { // Check before setState
        setState(() {
          allAuthors = authors;
          filteredAuthors = List.from(authors);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!_disposed) { // Check before setState
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading authors: ${e.toString()}';
        });
      }
    }
  }

  void searchAuthors(String query) {
    if (_disposed) return; // Check if disposed

    final lower = query.toLowerCase();
    setState(() {
      filteredAuthors = allAuthors.where((author) =>
      author.name.toLowerCase().contains(lower) ||
          author.email.toLowerCase().contains(lower)
      ).toList();
    });
  }

  Future<void> _refreshAuthors() async {
    await _fetchAuthors();
  }

  Future<void> _handleFollowToggle(AuthorModel author) async {
    try {
      final bool isCurrentlyFollowing = await AuthorService.isFollowing(author.id);

      if (isCurrentlyFollowing) {
        await AuthorService.unfollowAuthor(author.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unfollowed ${author.name}')),
          );
        }
      } else {
        await AuthorService.followAuthor(author.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Following ${author.name}')),
          );
        }
      }

      // Refresh the authors list to update follow counts
      _refreshAuthors();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating follow status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAuthorCard(AuthorModel author) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Author Profile Picture
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade300,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: _buildAuthorImage(author),
              ),
            ),
            SizedBox(width: 16),

            // Author Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    "${author.bookCount} ${author.bookCount == 1 ? 'book' : 'books'}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2),
                  Wrap(
                    spacing: 16,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: 16, color: Colors.grey.shade600),
                          SizedBox(width: 4),
                          Text(
                            "${author.followers} followers",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite_outline, size: 16, color: Colors.grey.shade600),
                          SizedBox(width: 4),
                          Text(
                            "${author.likes} likes",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Follow button
            FutureBuilder<bool>(
              future: AuthorService.isFollowing(author.id),
              builder: (context, snapshot) {
                final bool isFollowing = snapshot.data ?? false;
                return OutlinedButton(
                  onPressed: () => _handleFollowToggle(author),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isFollowing ? Theme.of(context).primaryColor : null,
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: TextStyle(
                      color: isFollowing ? Colors.white : Theme.of(context).primaryColor,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorImage(AuthorModel author) {
    if (author.profileImageUrl != null) {
      if (author.profileImageUrl!.startsWith('data:image')) {
        // Handle base64 data URL
        try {
          final base64String = author.profileImageUrl!.split(',')[1];
          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildDefaultAvatar(author.name),
          );
        } catch (e) {
          return _buildDefaultAvatar(author.name);
        }
      } else {
        // Handle regular URL
        return Image.network(
          author.profileImageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildDefaultAvatar(author.name),
        );
      }
    }
    return _buildDefaultAvatar(author.name);
  }

  Widget _buildDefaultAvatar(String name) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.7),
            Theme.of(context).primaryColor,
          ],
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Authors'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshAuthors,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 16),

          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: StandardSearchBar(
              width: double.infinity,
              horizontalPadding: 16,
              onChanged: searchAuthors,
            ),
          ),

          SizedBox(height: 16),

          // Content Area
          Expanded(
            child: _isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  SizedBox(height: 16),
                  Text('Loading authors...'),
                ],
              ),
            )
                : _errorMessage != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshAuthors,
                    child: Text('Retry'),
                  ),
                ],
              ),
            )
                : filteredAuthors.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No authors found",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (allAuthors.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        "Authors will appear here when users create books",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _refreshAuthors,
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: filteredAuthors.length,
                itemBuilder: (context, index) {
                  return _buildAuthorCard(filteredAuthors[index]);
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_rounded), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.my_library_books_rounded), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: 3, // Authors page index (assuming it's accessed from profile or general navigation)
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/');
          }
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WritingDashboard()),
            );
          }
          if (index == 2) {
            Navigator.pushReplacementNamed(context, '/library');
          }
          if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          }
        },
      ),
    );
  }
}
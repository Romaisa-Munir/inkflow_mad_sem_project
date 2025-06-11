import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/author_model.dart';

class AuthorService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fetches all authors from Firebase (users who have created books)
  static Future<List<AuthorModel>> fetchAuthors() async {
    try {
      // Get all users from Firebase
      final DatabaseEvent usersEvent = await _database.child('users').once();
      if (!usersEvent.snapshot.exists) {
        return [];
      }

      final Map<dynamic, dynamic> usersData =
      usersEvent.snapshot.value as Map<dynamic, dynamic>;

      List<AuthorModel> authors = [];

      // Process each user
      for (var userEntry in usersData.entries) {
        final String userId = userEntry.key;
        final Map<String, dynamic> userData =
        Map<String, dynamic>.from(userEntry.value);

        // Check if user has books (making them an author)
        int bookCount = 0;
        if (userData['books'] != null) {
          final Map<dynamic, dynamic> books = userData['books'];
          bookCount = books.length;
        }

        // Only include users who have created at least one book
        if (bookCount > 0) {
          // Extract profile data if it exists (matching your ProfilePage structure)
          Map<String, dynamic> profileData = {};
          if (userData['profile'] != null) {
            profileData = Map<String, dynamic>.from(userData['profile']);
          }

          final author = AuthorModel.fromMap(userId, {
            // Use profile data first, then fallback to root level data
            'name': profileData['username'] ?? userData['name'] ?? userData['displayName'],
            'email': userData['email'],
            'profileImageUrl': profileData['profilePicBase64'] != null
                ? 'data:image/jpeg;base64,${profileData['profilePicBase64']}'
                : userData['profileImageUrl'],
            'joinedDate': userData['createdAt'] != null
                ? DateTime.parse(userData['createdAt']).millisecondsSinceEpoch
                : userData['joinedDate'],
            'followers': userData['followers'] ?? 0,
            'likes': userData['likes'] ?? 0,
            'isAuthor': true,
            'bookCount': bookCount,
          });
          authors.add(author);
        }
      }

      // Sort authors by book count (most prolific first), then by name
      authors.sort((a, b) {
        final bookCountComparison = b.bookCount.compareTo(a.bookCount);
        if (bookCountComparison != 0) return bookCountComparison;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      return authors;
    } catch (e) {
      print('Error fetching authors: $e');
      return [];
    }
  }

  /// Updates user profile to include author information when they create their first book
  static Future<void> ensureAuthorProfile() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final String userId = currentUser.uid;
      final DatabaseReference userRef = _database.child('users/$userId');

      // Get current user data to see what profile info exists
      final DatabaseEvent userEvent = await userRef.once();
      Map<String, dynamic> userData = {};
      if (userEvent.snapshot.exists) {
        userData = Map<String, dynamic>.from(userEvent.snapshot.value as Map);
      }

      // Get profile data if it exists
      Map<String, dynamic> profileData = {};
      if (userData['profile'] != null) {
        profileData = Map<String, dynamic>.from(userData['profile']);
      }

      // Use existing username from profile, or create a fallback
      String displayName = profileData['username'] ??
          userData['name'] ??
          userData['displayName'] ??
          currentUser.displayName ??
          currentUser.email?.split('@')[0] ??
          'Author${userId.substring(0, 6)}';

      // Only update if the user doesn't already have a username set
      Map<String, dynamic> authorData = {};

      if (profileData['username'] == null || profileData['username'] == 'Your Username') {
        authorData['profile/username'] = displayName;
      }

      // Always update these fields
      authorData.addAll({
        'email': userData['email'] ?? currentUser.email ?? '',
        'followers': userData['followers'] ?? 0,
        'likes': userData['likes'] ?? 0,
        'isAuthor': true,
        'lastActive': DateTime.now().millisecondsSinceEpoch,
      });

      // Only update if we have something to update
      if (authorData.isNotEmpty) {
        await userRef.update(authorData);
      }

      print('Author profile updated successfully');
    } catch (e) {
      print('Error updating author profile: $e');
      rethrow;
    }
  }

  /// Call this function after successfully creating a book
  static Future<void> onBookCreated(String bookId) async {
    await ensureAuthorProfile();

    // Update book count and last book created timestamp
    try {
      final String userId = _auth.currentUser!.uid;
      final DatabaseReference userRef = _database.child('users/$userId');

      // Get current book count
      final DatabaseEvent booksEvent = await userRef.child('books').once();
      int bookCount = 0;
      if (booksEvent.snapshot.exists) {
        final Map<dynamic, dynamic> books = booksEvent.snapshot.value as Map<dynamic, dynamic>;
        bookCount = books.length;
      }

      // Update book count and timestamp
      await userRef.update({
        'bookCount': bookCount,
        'lastBookCreated': DateTime.now().millisecondsSinceEpoch,
        'lastActive': DateTime.now().millisecondsSinceEpoch,
      });

    } catch (e) {
      print('Error updating book count: $e');
      rethrow;
    }
  }

  /// Follow/Unfollow functionality (for future implementation)
  static Future<void> followAuthor(String authorId) async {
    try {
      final String currentUserId = _auth.currentUser!.uid;
      final DatabaseReference followRef = _database
          .child('users/$currentUserId/following/$authorId');
      final DatabaseReference followerRef = _database
          .child('users/$authorId/followers/$currentUserId');

      // Add to following and followers lists
      await followRef.set(DateTime.now().millisecondsSinceEpoch);
      await followerRef.set(DateTime.now().millisecondsSinceEpoch);

      // Update follower count
      final DatabaseEvent authorEvent = await _database.child('users/$authorId').once();
      if (authorEvent.snapshot.exists) {
        final Map<String, dynamic> authorData =
        Map<String, dynamic>.from(authorEvent.snapshot.value as Map);
        final int currentFollowers = authorData['followers'] ?? 0;
        await _database.child('users/$authorId').update({
          'followers': currentFollowers + 1,
        });
      }
    } catch (e) {
      print('Error following author: $e');
      rethrow;
    }
  }

  static Future<void> unfollowAuthor(String authorId) async {
    try {
      final String currentUserId = _auth.currentUser!.uid;
      final DatabaseReference followRef = _database
          .child('users/$currentUserId/following/$authorId');
      final DatabaseReference followerRef = _database
          .child('users/$authorId/followers/$currentUserId');

      // Remove from following and followers lists
      await followRef.remove();
      await followerRef.remove();

      // Update follower count
      final DatabaseEvent authorEvent = await _database.child('users/$authorId').once();
      if (authorEvent.snapshot.exists) {
        final Map<String, dynamic> authorData =
        Map<String, dynamic>.from(authorEvent.snapshot.value as Map);
        final int currentFollowers = authorData['followers'] ?? 0;
        await _database.child('users/$authorId').update({
          'followers': currentFollowers > 0 ? currentFollowers - 1 : 0,
        });
      }
    } catch (e) {
      print('Error unfollowing author: $e');
      rethrow;
    }
  }

  /// Check if current user is following a specific author
  static Future<bool> isFollowing(String authorId) async {
    try {
      final String currentUserId = _auth.currentUser!.uid;
      final DatabaseEvent followEvent = await _database
          .child('users/$currentUserId/following/$authorId')
          .once();
      return followEvent.snapshot.exists;
    } catch (e) {
      print('Error checking follow status: $e');
      return false;
    }
  }

}

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
        int totalLikes = 0;

        if (userData['books'] != null) {
          final Map<dynamic, dynamic> books = userData['books'];
          bookCount = books.length;

          // Calculate total likes across all books for this author
          for (var bookEntry in books.entries) {
            final String bookId = bookEntry.key;
            final Map<String, dynamic> bookData = Map<String, dynamic>.from(bookEntry.value);

            // Get likes count for this specific book
            int bookLikes = await _getBookLikesCount(bookId);
            totalLikes += bookLikes;

            // Update the book's likesCount in the author's collection if it's outdated
            if (bookData['likesCount'] != bookLikes) {
              await _database
                  .child('users/$userId/books/$bookId/likesCount')
                  .set(bookLikes);
            }
          }

          // Update author's total likes if it's different
          int storedLikes = userData['totalLikes'] ?? userData['likes'] ?? 0;
          if (storedLikes != totalLikes) {
            await _database.child('users/$userId').update({
              'totalLikes': totalLikes,
              'likes': totalLikes,
            });
          }
        }

        // Only include users who have created at least one book
        if (bookCount > 0) {
          // Extract profile data if it exists
          Map<String, dynamic> profileData = {};
          if (userData['profile'] != null) {
            profileData = Map<String, dynamic>.from(userData['profile']);
          }

          // Improved name resolution logic
          String authorName = _resolveAuthorName(profileData, userData, userId);

          final author = AuthorModel.fromMap(userId, {
            'name': authorName,
            'email': userData['email'] ?? '',
            'profileImageUrl': profileData['profilePicBase64'] != null
                ? 'data:image/jpeg;base64,${profileData['profilePicBase64']}'
                : userData['profileImageUrl'],
            'joinedDate': userData['createdAt'] != null
                ? DateTime.parse(userData['createdAt']).millisecondsSinceEpoch
                : userData['joinedDate'] ?? DateTime.now().millisecondsSinceEpoch,
            'followers': userData['followers'] ?? 0,
            'likes': totalLikes, // Use calculated total likes
            'isAuthor': true,
            'bookCount': bookCount,
          });
          authors.add(author);
        }
      }

      // Sort authors by total likes first, then by book count, then by name
      authors.sort((a, b) {
        final likesComparison = b.likes.compareTo(a.likes);
        if (likesComparison != 0) return likesComparison;

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

  /// Helper method to resolve the best author name from available data
  static String _resolveAuthorName(Map<String, dynamic> profileData, Map<String, dynamic> userData, String userId) {
    String? name;

    // First priority: profile username (if set and not default)
    name = profileData['username'];
    if (name != null && name.isNotEmpty && name != 'Your Username') {
      return name;
    }

    // Second priority: profile name
    name = profileData['name'];
    if (name != null && name.isNotEmpty && name != 'Your Username') {
      return name;
    }

    // Third priority: user data name
    name = userData['name'];
    if (name != null && name.isNotEmpty) {
      return name;
    }

    // Fourth priority: user data displayName
    name = userData['displayName'];
    if (name != null && name.isNotEmpty) {
      return name;
    }

    // Fifth priority: email prefix (if email exists)
    String? email = userData['email'];
    if (email != null && email.isNotEmpty) {
      String emailPrefix = email.split('@')[0];
      if (emailPrefix.isNotEmpty) {
        return emailPrefix;
      }
    }

    // Last resort: generate a user-friendly name
    return 'Author${userId.substring(0, 6)}';
  }

  /// Helper method to get likes count for a specific book
  static Future<int> _getBookLikesCount(String bookId) async {
    try {
      final DatabaseEvent likesEvent = await _database
          .child('books/$bookId/likes')
          .once();

      if (likesEvent.snapshot.exists && likesEvent.snapshot.value != null) {
        final Map<dynamic, dynamic> likesData = likesEvent.snapshot.value as Map<dynamic, dynamic>;
        return likesData.length;
      }
      return 0;
    } catch (e) {
      print('Error getting likes count for book $bookId: $e');
      return 0;
    }
  }

  /// Recalculates and updates an author's total likes
  static Future<void> recalculateAuthorLikes(String authorId) async {
    try {
      print('Recalculating likes for author: $authorId');

      // Get all books by this author
      final DatabaseEvent authorBooksEvent = await _database
          .child('users/$authorId/books')
          .once();

      int totalLikes = 0;
      int totalBooks = 0;

      if (authorBooksEvent.snapshot.exists && authorBooksEvent.snapshot.value != null) {
        final Map<dynamic, dynamic> booksData = authorBooksEvent.snapshot.value as Map<dynamic, dynamic>;
        totalBooks = booksData.length;

        // Count likes for each book
        for (String bookId in booksData.keys) {
          int bookLikes = await _getBookLikesCount(bookId);
          totalLikes += bookLikes;

          // Update the book's likesCount in the author's books collection
          await _database
              .child('users/$authorId/books/$bookId/likesCount')
              .set(bookLikes);
        }
      }

      // Update author's profile with calculated totals
      Map<String, dynamic> authorUpdates = {
        'totalLikes': totalLikes,
        'likes': totalLikes,
        'bookCount': totalBooks,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      };

      await _database.child('users/$authorId/profile').update(authorUpdates);
      await _database.child('users/$authorId').update(authorUpdates);

      print('Author $authorId updated: $totalLikes total likes across $totalBooks books');
    } catch (e) {
      print('Error recalculating author likes: $e');
      rethrow;
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

      // Calculate current total likes
      int totalLikes = await _calculateUserTotalLikes(userId);

      // Only update if the user doesn't already have a username set
      Map<String, dynamic> authorData = {};

      if (profileData['username'] == null || profileData['username'] == 'Your Username') {
        authorData['profile/username'] = displayName;
      }

      // Always update these fields
      authorData.addAll({
        'email': userData['email'] ?? currentUser.email ?? '',
        'followers': userData['followers'] ?? 0,
        'likes': totalLikes,
        'totalLikes': totalLikes,
        'isAuthor': true,
        'lastActive': DateTime.now().millisecondsSinceEpoch,
      });

      // Only update if we have something to update
      if (authorData.isNotEmpty) {
        await userRef.update(authorData);
      }

      print('Author profile updated successfully with $totalLikes total likes');
    } catch (e) {
      print('Error updating author profile: $e');
      rethrow;
    }
  }

  /// Calculate total likes across all books for a user
  static Future<int> _calculateUserTotalLikes(String userId) async {
    try {
      final DatabaseEvent booksEvent = await _database
          .child('users/$userId/books')
          .once();

      int totalLikes = 0;
      if (booksEvent.snapshot.exists && booksEvent.snapshot.value != null) {
        final Map<dynamic, dynamic> books = booksEvent.snapshot.value as Map<dynamic, dynamic>;

        for (String bookId in books.keys) {
          totalLikes += await _getBookLikesCount(bookId);
        }
      }

      return totalLikes;
    } catch (e) {
      print('Error calculating user total likes: $e');
      return 0;
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

      // Calculate total likes
      int totalLikes = await _calculateUserTotalLikes(userId);

      // Update book count, likes, and timestamp
      await userRef.update({
        'bookCount': bookCount,
        'totalLikes': totalLikes,
        'likes': totalLikes,
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
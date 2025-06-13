import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ReadingAnalyticsService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Start a reading session when user clicks "Read"
  static Future<String?> startReadingSession(String bookId, {String? chapterId}) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final String sessionId = _database.push().key!;
      final int timestamp = DateTime.now().millisecondsSinceEpoch;

      // Create session data
      Map<String, dynamic> sessionData = {
        'userId': currentUser.uid,
        'bookId': bookId,
        'startTime': timestamp,
        'timestamp': timestamp,
      };

      if (chapterId != null) {
        sessionData['chapterId'] = chapterId;
      }

      // Save the session
      await _database
          .child('book_analytics')
          .child(bookId)
          .child('reads')
          .child(sessionId)
          .set(sessionData);

      // Update reader info
      await _updateReaderInfo(bookId, currentUser.uid, timestamp);

      print('Started reading session: $sessionId for book: $bookId');
      return sessionId;
    } catch (e) {
      print('Error starting reading session: $e');
      return null;
    }
  }

  // End a reading session and calculate duration
  static Future<void> endReadingSession(String bookId, String sessionId) async {
    try {
      final int endTime = DateTime.now().millisecondsSinceEpoch;

      // Get the session start time
      DatabaseEvent sessionEvent = await _database
          .child('book_analytics')
          .child(bookId)
          .child('reads')
          .child(sessionId)
          .once();

      if (sessionEvent.snapshot.exists && sessionEvent.snapshot.value != null) {
        Map<String, dynamic> sessionData = Map<String, dynamic>.from(sessionEvent.snapshot.value as Map);
        int startTime = sessionData['startTime'] ?? endTime;
        int duration = endTime - startTime;

        // Update session with end time and duration
        await _database
            .child('book_analytics')
            .child(bookId)
            .child('reads')
            .child(sessionId)
            .update({
          'endTime': endTime,
          'duration': duration,
        });

        // Update reader's total reading time
        await _updateReaderReadingTime(bookId, sessionData['userId'], duration, endTime);

        print('Ended reading session: $sessionId, Duration: ${duration}ms');
      }
    } catch (e) {
      print('Error ending reading session: $e');
    }
  }

  // Update reader information
  static Future<void> _updateReaderInfo(String bookId, String userId, int timestamp) async {
    try {
      // Get user's display name
      DatabaseEvent userEvent = await _database.child('users').child(userId).once();
      String username = 'Unknown User';

      if (userEvent.snapshot.exists && userEvent.snapshot.value != null) {
        Map<String, dynamic> userData = Map<String, dynamic>.from(userEvent.snapshot.value as Map);

        // Try different possible name fields
        if (userData['library'] != null && userData['library']['name'] != null) {
          username = userData['library']['name'];
        } else if (userData['profile'] != null && userData['profile']['name'] != null) {
          username = userData['profile']['name'];
        } else if (userData['email'] != null) {
          username = userData['email'].split('@')[0]; // Use email prefix as fallback
        }
      }

      DatabaseReference readerRef = _database
          .child('book_analytics')
          .child(bookId)
          .child('readers')
          .child(userId);

      // Check if reader already exists
      DatabaseEvent readerEvent = await readerRef.once();

      if (readerEvent.snapshot.exists && readerEvent.snapshot.value != null) {
        // Update existing reader
        Map<String, dynamic> readerData = Map<String, dynamic>.from(readerEvent.snapshot.value as Map);
        int totalSessions = (readerData['totalSessions'] ?? 0) + 1;

        await readerRef.update({
          'lastRead': timestamp,
          'totalSessions': totalSessions,
          'username': username, // Update username in case it changed
        });
      } else {
        // Create new reader entry
        await readerRef.set({
          'username': username,
          'firstRead': timestamp,
          'lastRead': timestamp,
          'totalSessions': 1,
          'totalReadingTime': 0,
        });
      }
    } catch (e) {
      print('Error updating reader info: $e');
    }
  }

  // Update reader's total reading time
  static Future<void> _updateReaderReadingTime(String bookId, String userId, int sessionDuration, int timestamp) async {
    try {
      DatabaseReference readerRef = _database
          .child('book_analytics')
          .child(bookId)
          .child('readers')
          .child(userId);

      DatabaseEvent readerEvent = await readerRef.once();

      if (readerEvent.snapshot.exists && readerEvent.snapshot.value != null) {
        Map<String, dynamic> readerData = Map<String, dynamic>.from(readerEvent.snapshot.value as Map);
        int totalReadingTime = (readerData['totalReadingTime'] ?? 0) + sessionDuration;

        await readerRef.update({
          'totalReadingTime': totalReadingTime,
          'lastRead': timestamp,
        });
      }
    } catch (e) {
      print('Error updating reader reading time: $e');
    }
  }

  // Get analytics data for a specific book
  static Future<Map<String, dynamic>> getBookAnalytics(String bookId) async {
    try {
      Map<String, dynamic> analytics = {
        'uniqueReaders': 0,
        'totalReads': 0,
        'totalReadingTime': 0,
        'readers': <Map<String, dynamic>>[],
      };

      // Get readers data
      DatabaseEvent readersEvent = await _database
          .child('book_analytics')
          .child(bookId)
          .child('readers')
          .once();

      if (readersEvent.snapshot.exists && readersEvent.snapshot.value != null) {
        Map<dynamic, dynamic> readersData = readersEvent.snapshot.value as Map<dynamic, dynamic>;
        analytics['uniqueReaders'] = readersData.length;

        int totalReadingTime = 0;
        List<Map<String, dynamic>> readersList = [];

        readersData.forEach((userId, readerData) {
          if (readerData != null) {
            Map<String, dynamic> reader = Map<String, dynamic>.from(readerData);
            totalReadingTime += (reader['totalReadingTime'] as int? ?? 0);
            readersList.add({
              'userId': userId,
              'username': reader['username'] ?? 'Unknown User',
              'totalSessions': reader['totalSessions'] ?? 0,
              'totalReadingTime': reader['totalReadingTime'] ?? 0,
              'firstRead': reader['firstRead'] ?? 0,
              'lastRead': reader['lastRead'] ?? 0,
            });
          }
        });

        analytics['totalReadingTime'] = totalReadingTime;
        analytics['readers'] = readersList;
      }

      // Get total reads count
      DatabaseEvent readsEvent = await _database
          .child('book_analytics')
          .child(bookId)
          .child('reads')
          .once();

      if (readsEvent.snapshot.exists && readsEvent.snapshot.value != null) {
        Map<dynamic, dynamic> readsData = readsEvent.snapshot.value as Map<dynamic, dynamic>;
        analytics['totalReads'] = readsData.length;
      }

      return analytics;
    } catch (e) {
      print('Error getting book analytics: $e');
      return {
        'uniqueReaders': 0,
        'totalReads': 0,
        'totalReadingTime': 0,
        'readers': <Map<String, dynamic>>[],
      };
    }
  }

  // Simple method to increment read count (use when "Read" button is clicked)
  static Future<void> incrementReadCount(String bookId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final String sessionId = _database.push().key!;
      final int timestamp = DateTime.now().millisecondsSinceEpoch;

      // Record the read event
      await _database
          .child('book_analytics')
          .child(bookId)
          .child('reads')
          .child(sessionId)
          .set({
        'userId': currentUser.uid,
        'timestamp': timestamp,
        'duration': 0, // Will be updated when session ends
      });

      // Update reader info
      await _updateReaderInfo(bookId, currentUser.uid, timestamp);

      print('Read count incremented for book: $bookId');
    } catch (e) {
      print('Error incrementing read count: $e');
    }
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:inkflow_mad_sem_project/models/book_model.dart';
import 'package:inkflow_mad_sem_project/services/reading_analytics_service.dart';

class BookAnalyticsPage extends StatefulWidget {
  final Book book;

  const BookAnalyticsPage({super.key, required this.book});

  @override
  State<BookAnalyticsPage> createState() => _BookAnalyticsPageState();
}

class _BookAnalyticsPageState extends State<BookAnalyticsPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  int _totalLikes = 0;
  int _uniqueReaders = 0;
  int _totalReads = 0;
  int _totalReadingTimeMinutes = 0;
  int _libraryAdds = 0;
  double _totalEarnings = 0.0; // New field for earnings
  List<Map<String, dynamic>> _readersList = [];
  int _chaptersCount = 0;

  @override
  void initState() {
    super.initState();
    _loadBookAnalytics();
  }

  Future<void> _loadBookAnalytics() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load all analytics data including earnings
      await Future.wait([
        _loadBookData(),
        _loadReadingData(),
        _loadEarningsData(), // New method to load earnings
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading book analytics: $e');
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to load analytics data');
    }
  }

  // New method to load earnings data
  Future<void> _loadEarningsData() async {
    try {
      print('Loading earnings data for book: ${widget.book.id}');

      // Query the purchases node
      DatabaseEvent purchasesEvent = await _database.child('analytics').child('purchases').once();

      if (!purchasesEvent.snapshot.exists || purchasesEvent.snapshot.value == null) {
        print('No purchases found in analytics');
        setState(() {
          _totalEarnings = 0.0;
        });
        return;
      }

      Map<dynamic, dynamic> allPurchases = purchasesEvent.snapshot.value as Map<dynamic, dynamic>;
      double earnings = 0.0;

      // Iterate through all purchase records
      for (var purchaseKey in allPurchases.keys) {
        Map<dynamic, dynamic> purchase = allPurchases[purchaseKey] as Map<dynamic, dynamic>;

        // Check if this purchase is for our book
        if (purchase['bookId'] == widget.book.id) {
          double price = (purchase['price'] ?? 0).toDouble();
          earnings += price;
          print('Found purchase: $purchaseKey, Price: $price');
        }
      }

      setState(() {
        _totalEarnings = earnings;
      });

      print('Total earnings for book ${widget.book.id}: \$${earnings.toStringAsFixed(2)}');
    } catch (e) {
      print('Error loading earnings data: $e');
      setState(() {
        _totalEarnings = 0.0;
      });
    }
  }

  Future<void> _loadBookData() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get book data from user's books node
      DatabaseEvent bookEvent = await _database
          .child('users')
          .child(currentUser.uid)
          .child('books')
          .child(widget.book.id)
          .once();

      if (bookEvent.snapshot.exists && bookEvent.snapshot.value != null) {
        Map<String, dynamic> bookData = Map<String, dynamic>.from(bookEvent.snapshot.value as Map);

        // Get likes count from the book data
        _totalLikes = bookData['likesCount'] ?? 0;

        // Count chapters
        if (bookData['chapters'] != null) {
          Map<dynamic, dynamic> chapters = bookData['chapters'];
          _chaptersCount = chapters.length;
        }
      }

      print('Loaded book data: likes=$_totalLikes, chapters=$_chaptersCount');
    } catch (e) {
      print('Error loading book data: $e');
    }
  }

  Future<void> _loadReadingData() async {
    try {
      // Use the ReadingAnalyticsService to get analytics data
      Map<String, dynamic> analyticsData = await ReadingAnalyticsService.getBookAnalytics(widget.book.id);

      // Get library count
      int libraryCount = await _getLibraryCount();

      setState(() {
        _uniqueReaders = analyticsData['uniqueReaders'] ?? 0;
        _totalReads = analyticsData['totalReads'] ?? 0;

        // DON'T convert to minutes here - we'll format it properly in the display
        _totalReadingTimeMinutes = analyticsData['totalReadingTime'] ?? 0;

        // Set the library count
        _libraryAdds = libraryCount;

        // Process readers list
        List<dynamic> readers = analyticsData['readers'] ?? [];
        _readersList = readers.map((reader) => Map<String, dynamic>.from(reader)).toList();

        // Sort readers by total reading time (descending)
        _readersList.sort((a, b) => (b['totalReadingTime'] as int).compareTo(a['totalReadingTime'] as int));
      });

      print('Reading analytics loaded: Reads=$_totalReads, Unique=$_uniqueReaders, Time=${_totalReadingTimeMinutes}ms, Library=$_libraryAdds');
    } catch (e) {
      print('Error loading reading data: $e');
      // Set default values on error
      setState(() {
        _totalReads = 0;
        _uniqueReaders = 0;
        _totalReadingTimeMinutes = 0;
        _libraryAdds = 0;
        _readersList = [];
      });
    }
  }

  Future<int> _getLibraryCount() async {
    try {
      print('Counting library adds for book: ${widget.book.id}');

      // Get all users
      DatabaseEvent usersEvent = await _database.child('users').once();

      if (!usersEvent.snapshot.exists || usersEvent.snapshot.value == null) {
        print('No users found in database');
        return 0;
      }

      Map<dynamic, dynamic> allUsers = usersEvent.snapshot.value as Map<dynamic, dynamic>;
      int count = 0;

      // Check each user's library for this book
      for (String userId in allUsers.keys) {
        DatabaseEvent libraryEvent = await _database
            .child('users')
            .child(userId)
            .child('library')
            .child(widget.book.id)
            .once();

        if (libraryEvent.snapshot.exists) {
          count++;
          print('User $userId has book in library');
        }
      }

      print('Total library adds found: $count');
      return count;
    } catch (e) {
      print('Error counting library adds: $e');
      return 0;
    }
  }

  // Add this new method to format reading time properly
  String _formatReadingTime(int milliseconds) {
    if (milliseconds < 60000) {
      // Less than 1 minute - show seconds
      int seconds = (milliseconds / 1000).round();
      return '${seconds}s';
    } else {
      // 1 minute or more - show minutes
      int minutes = (milliseconds / 60000).round();
      return '${minutes}m';
    }
  }

  // New method to format earnings
  String _formatEarnings(double earnings) {
    return 'PKR ${earnings.toStringAsFixed(2)}';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadersSection() {
    if (_readersList.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
              SizedBox(height: 12),
              Text(
                'No reading data yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Reading tracking will appear here once implemented',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Top Readers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...(_readersList.take(5).map((reader) => Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      reader['username'].toString().substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reader['username'],
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${reader['totalSessions']} sessions • ${((reader['totalReadingTime'] ?? 0) / 60000).round()} min read',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatLastRead(reader['lastRead']),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )).toList()),
          ],
        ),
      ),
    );
  }

  String _formatLastRead(int timestamp) {
    if (timestamp == 0) return 'Never';

    DateTime lastRead = DateTime.fromMillisecondsSinceEpoch(timestamp);
    DateTime now = DateTime.now();
    Duration difference = now.difference(lastRead);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.book.title} - Analytics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadBookAnalytics,
            tooltip: 'Refresh Analytics',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analytics Overview Cards
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildAnalyticsCard(
                  'Total Earnings',
                  _formatEarnings(_totalEarnings),
                  Icons.payments,
                  Colors.green,
                ),
                _buildAnalyticsCard(
                  'Total Likes',
                  _totalLikes.toString(),
                  Icons.favorite,
                  Colors.red,
                ),
                _buildAnalyticsCard(
                  'Unique Readers',
                  _uniqueReaders.toString(),
                  Icons.people,
                  Colors.blue,
                ),
                _buildAnalyticsCard(
                  'Total Reads',
                  _totalReads.toString(),
                  Icons.visibility,
                  Colors.green,
                ),
                _buildAnalyticsCard(
                  'Reading Time',
                  _formatReadingTime(_totalReadingTimeMinutes),
                  Icons.access_time,
                  Colors.orange,
                ),
                _buildAnalyticsCard(
                  'Library Adds',
                  _libraryAdds.toString(),
                  Icons.library_books,
                  Colors.purple,
                ),
              ],
            ),

            SizedBox(height: 24),

            // Book Info Section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.book, color: Colors.purple),
                        SizedBox(width: 8),
                        Text(
                          'Book Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _buildInfoRow('Title', widget.book.title),
                    _buildInfoRow('Status', widget.book.status.toUpperCase()),
                    _buildInfoRow('Created', _formatDate(widget.book.createdAt)),
                    _buildInfoRow('Chapters', _chaptersCount.toString()),
                    _buildInfoRow('Current Likes', _totalLikes.toString()),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Readers Section
            _buildReadersSection(),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(int timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month}/${date.year}';
  }
}
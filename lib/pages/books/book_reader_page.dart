import 'package:flutter/material.dart';
import 'package:inkflow_mad_sem_project/services/reading_analytics_service.dart';
import 'package:inkflow_mad_sem_project/services/payment_service.dart';
import 'package:inkflow_mad_sem_project/pages/payment/payment_dialog.dart';
import 'package:inkflow_mad_sem_project/pages/profile/settings_page.dart';

class BookReaderPage extends StatefulWidget {
  final List<Map<String, dynamic>> chapters;
  final String bookTitle;
  final String? bookId;
  final int initialChapterIndex; // Add this parameter

  const BookReaderPage({
    Key? key,
    required this.chapters,
    required this.bookTitle,
    this.bookId,
    this.initialChapterIndex = 0, // Default to first chapter
  }) : super(key: key);

  @override
  _BookReaderPageState createState() => _BookReaderPageState();
}

class _BookReaderPageState extends State<BookReaderPage> {
  PageController _pageController = PageController();
  int _currentChapterIndex = 0;
  late List<Map<String, dynamic>> _sortedChapters;
  double _fontSize = 18.0;
  bool _isDarkMode = false;
  String? _currentSessionId;
  String? _bookId;

  // Payment-related state
  Map<String, bool> _purchasedChapters = {};
  bool _isLoadingPurchases = true;
  String? _pendingPaymentMessage;

  @override
  void initState() {
    super.initState();

    // Set initial chapter index
    _currentChapterIndex = widget.initialChapterIndex;

    // Debug: Print original chapters before sorting
    print('=== ORIGINAL CHAPTERS BEFORE SORTING ===');
    for (int i = 0; i < widget.chapters.length; i++) {
      var chapter = widget.chapters[i];
      print('Chapter $i: "${chapter['title']}" (order: ${chapter['order']})');
    }

    // Sort chapters with intelligent strategy
    _sortedChapters = List.from(widget.chapters);

    // Strategy 1: Try sorting by extracting numbers from titles first
    print('=== TRYING TITLE-BASED SORTING ===');
    _sortedChapters.sort((a, b) {
      String titleA = (a['title'] ?? '').toLowerCase();
      String titleB = (b['title'] ?? '').toLowerCase();

      // Extract numbers from titles like "chapter 1", "chapter 2", etc.
      RegExp numberRegex = RegExp(r'(\d+)');
      var matchA = numberRegex.firstMatch(titleA);
      var matchB = numberRegex.firstMatch(titleB);

      if (matchA != null && matchB != null) {
        int numA = int.parse(matchA.group(1)!);
        int numB = int.parse(matchB.group(1)!);
        print('Comparing: "$titleA" (num: $numA) vs "$titleB" (num: $numB)');
        return numA.compareTo(numB);
      }

      // If no numbers found, sort alphabetically
      print('No numbers found, sorting alphabetically: "$titleA" vs "$titleB"');
      return titleA.compareTo(titleB);
    });

    // Debug: Print after title sorting
    print('=== AFTER TITLE-BASED SORTING ===');
    for (int i = 0; i < _sortedChapters.length; i++) {
      var chapter = _sortedChapters[i];
      print('Position $i: "${chapter['title']}" (order: ${chapter['order']})');
    }

    // Strategy 2: Check if the order field makes sense
    bool orderFieldMakesSense = true;
    if (_sortedChapters.length > 1) {
      // Check if order field is logical (ascending and reasonable)
      for (int i = 0; i < _sortedChapters.length - 1; i++) {
        int currentOrder = _sortedChapters[i]['order'] ?? i;
        int nextOrder = _sortedChapters[i + 1]['order'] ?? i + 1;

        // If order field doesn't increase logically, it's probably wrong
        if (currentOrder >= nextOrder) {
          orderFieldMakesSense = false;
          print('Order field seems wrong: Chapter "${_sortedChapters[i]['title']}" has order $currentOrder, but next chapter "${_sortedChapters[i + 1]['title']}" has order $nextOrder');
          break;
        }
      }
    }

    // Strategy 3: If order field seems reliable, use it instead
    if (orderFieldMakesSense && _sortedChapters.every((ch) => ch['order'] != null)) {
      print('=== ORDER FIELD SEEMS RELIABLE, RE-SORTING BY ORDER ===');
      _sortedChapters.sort((a, b) {
        int orderA = a['order'] ?? 999;
        int orderB = b['order'] ?? 999;
        return orderA.compareTo(orderB);
      });

      print('=== AFTER ORDER-BASED SORTING ===');
      for (int i = 0; i < _sortedChapters.length; i++) {
        var chapter = _sortedChapters[i];
        print('Position $i: "${chapter['title']}" (order: ${chapter['order']})');
      }
    } else {
      print('=== STICKING WITH TITLE-BASED SORTING ===');
    }

    // Ensure initial chapter index is valid
    if (_currentChapterIndex >= _sortedChapters.length) {
      _currentChapterIndex = 0;
    }

    // Initialize PageController with the initial chapter index
    _pageController = PageController(initialPage: _currentChapterIndex);

    print('BookReaderPage initialized with ${_sortedChapters.length} chapters');
    print('Starting with chapter: ${_sortedChapters[_currentChapterIndex]['title']}');

    // Load purchased chapters and start reading session
    _loadPurchasedChapters();
    _startReadingSession();

    // Check for pending payment message
    _checkPendingPaymentMessage();
  }

  // Load user's purchased chapters
  void _loadPurchasedChapters() async {
    if (widget.bookId == null) {
      setState(() {
        _isLoadingPurchases = false;
      });
      return;
    }

    try {
      final purchasedChapterIds = await PaymentService.getUserPurchasedChapters(widget.bookId!);

      setState(() {
        _purchasedChapters.clear();
        for (String chapterId in purchasedChapterIds) {
          _purchasedChapters[chapterId] = true;
        }
        _isLoadingPurchases = false;
      });

      print('Loaded ${purchasedChapterIds.length} purchased chapters');
    } catch (e) {
      print('Error loading purchased chapters: $e');
      setState(() {
        _isLoadingPurchases = false;
      });
    }
  }

  // Check for pending payment success message
  void _checkPendingPaymentMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['paymentSuccess'] == true) {
        _showPaymentSuccessMessage();
      }
    });
  }

  void _showPaymentSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Payment successful! Chapter unlocked.'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Check if chapter is accessible (free or purchased)
  bool _isChapterAccessible(Map<String, dynamic> chapter) {
    final price = (chapter['price'] ?? 0.0).toDouble();
    if (price == 0.0) return true; // Free chapters

    final chapterId = chapter['id']?.toString();
    if (chapterId == null) return true;

    return _purchasedChapters[chapterId] ?? false;
  }

  // Handle chapter access (payment flow)
  Future<void> _handleChapterAccess(Map<String, dynamic> chapter) async {
    final price = (chapter['price'] ?? 0.0).toDouble();
    if (price == 0.0) return; // Free chapter, no payment needed

    final chapterId = chapter['id']?.toString();
    if (chapterId == null) return;

    // Check if already purchased
    if (_purchasedChapters[chapterId] == true) return;

    try {
      // Check if user has payment info
      final hasPaymentInfo = await PaymentService.hasCompletePaymentInfo();

      if (!hasPaymentInfo) {
        _showPaymentInfoDialog(chapter);
        return;
      }

      // Show payment dialog
      _showPaymentDialog(chapter);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking payment info: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPaymentInfoDialog(Map<String, dynamic> chapter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.payment, color: Colors.orange),
            SizedBox(width: 10),
            Text('Payment Setup Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'To purchase chapters, please set up your payment information first.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Text(
                'You\'ll be redirected to your profile page to complete the payment setup.',
                style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Navigate to settings page with return route
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(),
                  settings: RouteSettings(
                    arguments: {
                      'returnRoute': '/book_reader',
                      'returnArgs': {
                        'paymentSuccess': true,
                        'chapters': widget.chapters,
                        'bookTitle': widget.bookTitle,
                        'bookId': widget.bookId,
                      },
                    },
                  ),
                ),
              );

              // Reload purchased chapters when returning
              if (result == true) {
                _loadPurchasedChapters();
                _showPaymentSuccessMessage();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('Setup Payment'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(Map<String, dynamic> chapter) {
    final price = (chapter['price'] ?? 0.0).toDouble();
    final chapterTitle = chapter['title'] ?? 'Untitled Chapter';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(
        chapterTitle: chapterTitle,
        price: price,
        onPaymentSuccess: () async {
          await _processPayment(chapter);
        },
        onNavigateToProfile: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SettingsPage()),
          );
          if (result == true) {
            _loadPurchasedChapters();
          }
        },
      ),
    );
  }

  Future<void> _processPayment(Map<String, dynamic> chapter) async {
    if (widget.bookId == null) return;

    final chapterId = chapter['id']?.toString();
    if (chapterId == null) return;

    final price = (chapter['price'] ?? 0.0).toDouble();

    try {
      await PaymentService.purchaseChapter(widget.bookId!, chapterId, price);

      setState(() {
        _purchasedChapters[chapterId] = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Chapter purchased successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Add this new method after initState
  void _startReadingSession() async {
    try {
      if (widget.bookId != null) {
        _bookId = widget.bookId;
        _currentSessionId = await ReadingAnalyticsService.startReadingSession(_bookId!);
        print('Started reading session: $_currentSessionId for book: $_bookId');
      } else {
        print('No book ID provided, cannot track reading time');
      }
    } catch (e) {
      print('Error starting reading session: $e');
    }
  }

  @override
  void dispose() {
    // END READING TIME TRACKING
    _endReadingSession();

    _pageController.dispose();
    super.dispose();
  }

  // Add this new method after dispose
  void _endReadingSession() async {
    try {
      if (_currentSessionId != null && _bookId != null) {
        await ReadingAnalyticsService.endReadingSession(_bookId!, _currentSessionId!);
        print('Ended reading session: $_currentSessionId');
      } else {
        print('No active reading session to end');
      }
    } catch (e) {
      print('Error ending reading session: $e');
    }
  }

  void _goToNextChapter() {
    if (_currentChapterIndex < _sortedChapters.length - 1) {
      final nextChapter = _sortedChapters[_currentChapterIndex + 1];

      // Check if next chapter is accessible
      if (!_isChapterAccessible(nextChapter)) {
        _handleChapterAccess(nextChapter);
        return;
      }

      setState(() {
        _currentChapterIndex++;
      });
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousChapter() {
    if (_currentChapterIndex > 0) {
      setState(() {
        _currentChapterIndex--;
      });
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(  // Add StatefulBuilder here
        builder: (BuildContext context, StateSetter setModalState) => Container(
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reading Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 20),

              // Font Size
              Text(
                'Font Size',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              Slider(
                value: _fontSize,
                min: 14.0,
                max: 24.0,
                divisions: 5,
                label: _fontSize.round().toString(),
                onChanged: (value) {
                  // Update both the modal state and the main widget state
                  setModalState(() {
                    _fontSize = value;
                  });
                  setState(() {
                    _fontSize = value;
                  });
                },
              ),

              // Dark Mode Toggle
              SwitchListTile(
                title: Text(
                  'Dark Mode',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                value: _isDarkMode,
                onChanged: (value) {
                  // Update both the modal state and the main widget state
                  setModalState(() {
                    _isDarkMode = value;
                  });
                  setState(() {
                    _isDarkMode = value;
                  });
                },
              ),

              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterNavigation() {
    final currentChapter = _sortedChapters[_currentChapterIndex];
    final isCurrentAccessible = _isChapterAccessible(currentChapter);
    final nextChapterAccessible = _currentChapterIndex < _sortedChapters.length - 1
        ? _isChapterAccessible(_sortedChapters[_currentChapterIndex + 1])
        : false;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDarkMode ? Colors.grey[700]! : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: (_isDarkMode ? Colors.black : Colors.grey).withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Button
          _buildNavButton(
            icon: Icons.arrow_back_ios,
            label: 'Previous',
            isEnabled: _currentChapterIndex > 0,
            onPressed: _goToPreviousChapter,
          ),

          // Chapter Info
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isCurrentAccessible) ...[
                      Icon(
                        Icons.lock,
                        size: 16,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        currentChapter['title'] ?? 'Chapter ${_currentChapterIndex + 1}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCurrentAccessible
                              ? (_isDarkMode ? Colors.white : Colors.deepPurple)
                              : Colors.orange,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '${_currentChapterIndex + 1} of ${_sortedChapters.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                if (!isCurrentAccessible) ...[
                  SizedBox(height: 4),
                  Text(
                    'PKR ${(currentChapter['price'] ?? 0.0).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Next Button
          _buildNavButton(
            icon: _currentChapterIndex < _sortedChapters.length - 1 && !nextChapterAccessible
                ? Icons.payment
                : Icons.arrow_forward_ios,
            label: _currentChapterIndex < _sortedChapters.length - 1 && !nextChapterAccessible
                ? 'Buy'
                : 'Next',
            isEnabled: _currentChapterIndex < _sortedChapters.length - 1,
            onPressed: _goToNextChapter,
            isPurchase: _currentChapterIndex < _sortedChapters.length - 1 && !nextChapterAccessible,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool isEnabled,
    required VoidCallback onPressed,
    bool isPurchase = false,
  }) {
    return Container(
      width: 80,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? (isPurchase
              ? Colors.orange
              : (_isDarkMode ? Colors.deepPurple[300] : Colors.deepPurple))
              : (_isDarkMode ? Colors.grey[700] : Colors.grey[300]),
          foregroundColor: isEnabled ? Colors.white : Colors.grey[500],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(vertical: 8),
          elevation: isEnabled ? 2 : 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterContent(Map<String, dynamic> chapter) {
    final isAccessible = _isChapterAccessible(chapter);
    final price = (chapter['price'] ?? 0.0).toDouble();

    if (!isAccessible) {
      return _buildLockedChapterContent(chapter, price);
    }

    return Container(
      color: _isDarkMode ? Colors.grey[900] : Colors.white,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        physics: BouncingScrollPhysics(), // Better scroll physics
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chapter Title
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                chapter['title'] ?? 'Untitled Chapter',
                style: TextStyle(
                  fontSize: _fontSize + 8,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Divider
            Container(
              height: 1,
              margin: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Chapter Content
            Container(
              width: double.infinity,
              child: Text(
                chapter['content'] ?? 'No content available.',
                style: TextStyle(
                  fontSize: _fontSize,
                  height: 1.7,
                  color: _isDarkMode ? Colors.grey[200] : Colors.black87,
                  letterSpacing: 0.3,
                  wordSpacing: 1.2,
                ),
                textAlign: TextAlign.justify,
              ),
            ),

            SizedBox(height: 60),

            // Chapter Navigation Footer
            if (_sortedChapters.length > 1)
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (_currentChapterIndex > 0)
                        ElevatedButton.icon(
                          onPressed: _goToPreviousChapter,
                          icon: Icon(Icons.arrow_back),
                          label: Text('Previous Chapter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isDarkMode ? Colors.grey[700] : Colors.grey[200],
                            foregroundColor: _isDarkMode ? Colors.white : Colors.black87,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),

                      if (_currentChapterIndex < _sortedChapters.length - 1)
                        ElevatedButton.icon(
                          onPressed: _goToNextChapter,
                          icon: Icon(Icons.arrow_forward),
                          label: Text('Next Chapter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isDarkMode ? Colors.deepPurple[300] : Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),

                      if (_currentChapterIndex == _sortedChapters.length - 1)
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'End of Book',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: _isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedChapterContent(Map<String, dynamic> chapter, double price) {
    return Container(
      color: _isDarkMode ? Colors.grey[900] : Colors.white,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lock Icon
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock,
                  size: 64,
                  color: Colors.orange[700],
                ),
              ),

              SizedBox(height: 32),

              // Chapter Title
              Text(
                chapter['title'] ?? 'Locked Chapter',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 16),

              // Price Info
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Text(
                  'PKR ${price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Description
              Text(
                'This chapter requires a one-time purchase to unlock. Once purchased, you\'ll have permanent access to read it anytime.',
                style: TextStyle(
                  fontSize: 16,
                  color: _isDarkMode ? Colors.grey[300] : Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 32),

              // Purchase Button
              ElevatedButton.icon(
                onPressed: () => _handleChapterAccess(chapter),
                icon: Icon(Icons.payment),
                label: Text('Purchase Chapter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 4,
                ),
              ),

              SizedBox(height: 16),

              // Demo Notice
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Demo payment - no real money charged',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPurchases) {
      return Scaffold(
        backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading chapters...',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: Text(
          widget.bookTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: _isDarkMode ? Colors.white : Colors.deepPurple,
          ),
        ),
        backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.deepPurple.shade50,
        elevation: 0,
        iconTheme: IconThemeData(
          color: _isDarkMode ? Colors.white : Colors.deepPurple,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _showSettingsMenu,
            tooltip: 'Reading Settings',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _loadPurchasedChapters();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Reader refreshed'),
                  duration: Duration(seconds: 1),
                  backgroundColor: Colors.green,
                ),
              );
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Navigation
          Padding(
            padding: EdgeInsets.only(top: 16, bottom: 8),
            child: _buildChapterNavigation(),
          ),

          // Chapter Content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _sortedChapters.length,
              onPageChanged: (index) {
                setState(() {
                  _currentChapterIndex = index;
                });
                print('Switched to chapter ${index + 1}: ${_sortedChapters[index]['title']}');
              },
              itemBuilder: (context, index) {
                return _buildChapterContent(_sortedChapters[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
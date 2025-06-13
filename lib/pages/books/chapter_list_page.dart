import 'package:flutter/material.dart';
import 'package:inkflow_mad_sem_project/services/payment_service.dart';
import 'package:inkflow_mad_sem_project/pages/books/book_reader_page.dart';
import 'package:inkflow_mad_sem_project/pages/payment/payment_dialog.dart';
import 'package:inkflow_mad_sem_project/pages/profile/settings_page.dart';

class ChapterListPage extends StatefulWidget {
  final List<Map<String, dynamic>> chapters;
  final String bookTitle;
  final String? bookId;
  final String? bookCover;
  final String? bookDescription;

  const ChapterListPage({
    Key? key,
    required this.chapters,
    required this.bookTitle,
    this.bookId,
    this.bookCover,
    this.bookDescription,
  }) : super(key: key);

  @override
  _ChapterListPageState createState() => _ChapterListPageState();
}

class _ChapterListPageState extends State<ChapterListPage> {
  late List<Map<String, dynamic>> _sortedChapters;
  Map<String, bool> _purchasedChapters = {};
  bool _isLoadingPurchases = true;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _sortChapters();
    _loadPurchasedChapters();
  }

  void _sortChapters() {
    _sortedChapters = List.from(widget.chapters);

    // Sort chapters by extracting numbers from titles first
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
        return numA.compareTo(numB);
      }

      // If no numbers found, sort alphabetically
      return titleA.compareTo(titleB);
    });

    // Check if order field makes sense and use it if reliable
    bool orderFieldMakesSense = true;
    if (_sortedChapters.length > 1) {
      for (int i = 0; i < _sortedChapters.length - 1; i++) {
        int currentOrder = _sortedChapters[i]['order'] ?? i;
        int nextOrder = _sortedChapters[i + 1]['order'] ?? i + 1;
        if (currentOrder >= nextOrder) {
          orderFieldMakesSense = false;
          break;
        }
      }
    }

    if (orderFieldMakesSense && _sortedChapters.every((ch) => ch['order'] != null)) {
      _sortedChapters.sort((a, b) {
        int orderA = a['order'] ?? 999;
        int orderB = b['order'] ?? 999;
        return orderA.compareTo(orderB);
      });
    }
  }

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
    } catch (e) {
      print('Error loading purchased chapters: $e');
      setState(() {
        _isLoadingPurchases = false;
      });
    }
  }

  bool _isChapterAccessible(Map<String, dynamic> chapter) {
    final price = (chapter['price'] ?? 0.0).toDouble();
    if (price == 0.0) return true; // Free chapters

    final chapterId = chapter['id']?.toString();
    if (chapterId == null) return true;

    return _purchasedChapters[chapterId] ?? false;
  }

  String _generatePreview(String content, int wordLimit) {
    if (content.isEmpty) return 'No preview available...';

    final words = content.split(' ');
    if (words.length <= wordLimit) return content;

    return '${words.take(wordLimit).join(' ')}...';
  }

  void _handleChapterTap(Map<String, dynamic> chapter, int chapterIndex) async {
    final price = (chapter['price'] ?? 0.0).toDouble();

    // If free chapter, go directly to reader
    if (price == 0.0) {
      _navigateToReader(chapterIndex);
      return;
    }

    // Check if already purchased
    final chapterId = chapter['id']?.toString();
    if (chapterId != null && _purchasedChapters[chapterId] == true) {
      _navigateToReader(chapterIndex);
      return;
    }

    // Show payment flow for paid chapters
    await _handleChapterPurchase(chapter, chapterIndex);
  }

  void _navigateToReader(int startingChapterIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookReaderPage(
          chapters: _sortedChapters,
          bookTitle: widget.bookTitle,
          bookId: widget.bookId,
          initialChapterIndex: startingChapterIndex,
        ),
      ),
    );
  }

  Future<void> _handleChapterPurchase(Map<String, dynamic> chapter, int chapterIndex) async {
    try {
      // Check if user has payment info
      final hasPaymentInfo = await PaymentService.hasCompletePaymentInfo();

      if (!hasPaymentInfo) {
        _showPaymentInfoDialog(chapter, chapterIndex);
        return;
      }

      // Show payment dialog
      _showPaymentDialog(chapter, chapterIndex);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking payment info: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPaymentInfoDialog(Map<String, dynamic> chapter, int chapterIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Container( // Replace LayoutBuilder with this
          width: double.infinity,
          child: Row(
            children: [
              Icon(Icons.payment, color: Colors.orange),
              SizedBox(width: 10),
              Expanded(
                child: Text('Payment Setup Required'),
              ),
            ],
          ),
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

              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );

              if (result == true) {
                _loadPurchasedChapters();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Payment setup completed!'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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

  void _showPaymentDialog(Map<String, dynamic> chapter, int chapterIndex) {
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
          _navigateToReader(chapterIndex);
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

  Widget _buildBookHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade100,
            Colors.deepPurple.shade50,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Cover
              if (widget.bookCover != null) ...[
                Container(
                  width: 80,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.bookCover!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.book, size: 40, color: Colors.grey[600]),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(width: 16),
              ],

              // Book Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.bookTitle,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${_sortedChapters.length} chapters',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.deepPurple.shade600,
                      ),
                    ),
                    if (widget.bookDescription != null) ...[
                      SizedBox(height: 8),
                      Text(
                        _generatePreview(widget.bookDescription!, 15),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
// Replace your ENTIRE _buildChapterCard method with this:
  Widget _buildChapterCard(Map<String, dynamic> chapter, int index) {
    final price = (chapter['price'] ?? 0.0).toDouble();
    final isAccessible = _isChapterAccessible(chapter);
    final chapterTitle = chapter['title'] ?? 'Chapter ${index + 1}';
    final chapterContent = chapter['content'] ?? '';
    final preview = _generatePreview(chapterContent, 20);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleChapterTap(chapter, index),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row - FIXED
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      width: constraints.maxWidth,
                      child: Row(
                        children: [
                          // Chapter Number
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isAccessible ? Colors.deepPurple : Colors.orange,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 12),

                          // Title and Status - FIXED
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title Row - FIXED
                                LayoutBuilder(
                                  builder: (context, titleConstraints) {
                                    return Container(
                                      width: titleConstraints.maxWidth,
                                      child: Row(
                                        children: [
                                          if (!isAccessible && price > 0) ...[
                                            Icon(
                                              Icons.lock,
                                              size: 16,
                                              color: Colors.orange,
                                            ),
                                            SizedBox(width: 4),
                                          ],
                                          Expanded(
                                            child: Text(
                                              chapterTitle,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: isAccessible ? Colors.black87 : Colors.orange.shade700,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                                // Price Row - COMPLETELY FIXED
                                if (price > 0) ...[
                                  SizedBox(height: 4),
                                  LayoutBuilder(
                                    builder: (context, priceConstraints) {
                                      return Container(
                                        width: priceConstraints.maxWidth,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                'PKR ${price.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  fontSize: 13, // Further reduced
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orange[700],
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                            SizedBox(width: 4), // Minimal spacing
                                            Expanded(
                                              flex: 4,
                                              child: Container(
                                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  'Demo',
                                                  style: TextStyle(
                                                    fontSize: 9, // Much smaller
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ] else ...[
                                  SizedBox(height: 4),
                                  LayoutBuilder(
                                    builder: (context, freeConstraints) {
                                      return Container(
                                        width: freeConstraints.maxWidth,
                                        child: Row(
                                          children: [
                                            Icon(Icons.free_breakfast, size: 14, color: Colors.green),
                                            SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                'Free',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),

                          SizedBox(width: 8),

                          // Action Icon
                          Icon(
                            isAccessible ? Icons.play_arrow : (price > 0 ? Icons.payment : Icons.play_arrow),
                            color: isAccessible ? Colors.deepPurple : Colors.orange,
                            size: 24,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(height: 12),

                // Preview Text
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    preview,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                SizedBox(height: 8),

                // Action Row - FIXED
                LayoutBuilder(
                  builder: (context, actionConstraints) {
                    return Container(
                      width: actionConstraints.maxWidth,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              isAccessible ? 'Tap to read' : (price > 0 ? 'Tap to purchase' : 'Tap to read'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (!isAccessible && price > 0) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Text(
                                'Demo',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPurchases) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Chapters'),
          backgroundColor: Colors.deepPurple.shade50,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading chapters...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Chapters',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple.shade800,
          ),
        ),
        backgroundColor: Colors.deepPurple.shade50,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.deepPurple.shade800),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _loadPurchasedChapters();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Chapters refreshed'),
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
          // Book Header
          _buildBookHeader(),

          // Chapters List
          Expanded(
            child: _sortedChapters.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_books,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No chapters available',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: _sortedChapters.length,
              itemBuilder: (context, index) {
                return _buildChapterCard(_sortedChapters[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

class BookReaderPage extends StatefulWidget {
  final List<Map<String, dynamic>> chapters;
  final String bookTitle;

  const BookReaderPage({
    Key? key,
    required this.chapters,
    required this.bookTitle,
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

  @override
  void initState() {
    super.initState();

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

    print('BookReaderPage initialized with ${_sortedChapters.length} chapters');
    print('Starting with chapter: ${_sortedChapters[_currentChapterIndex]['title']}');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextChapter() {
    if (_currentChapterIndex < _sortedChapters.length - 1) {
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
                Text(
                  _sortedChapters[_currentChapterIndex]['title'] ?? 'Chapter ${_currentChapterIndex + 1}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : Colors.deepPurple,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  '${_currentChapterIndex + 1} of ${_sortedChapters.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Next Button
          _buildNavButton(
            icon: Icons.arrow_forward_ios,
            label: 'Next',
            isEnabled: _currentChapterIndex < _sortedChapters.length - 1,
            onPressed: _goToNextChapter,
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
  }) {
    return Container(
      width: 80,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? (_isDarkMode ? Colors.deepPurple[300] : Colors.deepPurple)
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

  @override
  Widget build(BuildContext context) {
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
              setState(() {
                // Refresh the current state
              });
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
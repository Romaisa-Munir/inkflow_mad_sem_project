import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PaymentService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Check if user has purchased a specific chapter
  static Future<bool> hasUserPurchasedChapter(String bookId, String chapterId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final snapshot = await _database
          .child('users')
          .child(currentUser.uid)
          .child('purchasedChapters')
          .child(bookId)
          .child(chapterId)
          .get();

      return snapshot.exists;
    } catch (e) {
      print('Error checking chapter purchase: $e');
      return false;
    }
  }

  /// Check if user has complete payment information
  static Future<bool> hasCompletePaymentInfo() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final snapshot = await _database
          .child('users')
          .child(currentUser.uid)
          .child('paymentInfo')
          .get();

      if (!snapshot.exists) return false;

      final paymentData = Map<String, dynamic>.from(snapshot.value as Map);

      // Check if at least one payment method is filled
      final hasBank = (paymentData['bankAccountNumber']?.toString().isNotEmpty ?? false) &&
          (paymentData['ibanNumber']?.toString().isNotEmpty ?? false);
      final hasJazzCash = paymentData['jazzCashNumber']?.toString().isNotEmpty ?? false;
      final hasEasyPaisa = paymentData['easyPaisaNumber']?.toString().isNotEmpty ?? false;

      return hasBank || hasJazzCash || hasEasyPaisa;
    } catch (e) {
      print('Error checking payment info: $e');
      return false;
    }
  }

  /// Process chapter purchase (demo - just marks as purchased)
  static Future<bool> purchaseChapter(String bookId, String chapterId, double price) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Check if user has payment info
      if (!await hasCompletePaymentInfo()) {
        throw Exception('Payment information incomplete');
      }

      // Simulate payment processing delay
      await Future.delayed(Duration(milliseconds: 1500));

      // Mark chapter as purchased
      await _database
          .child('users')
          .child(currentUser.uid)
          .child('purchasedChapters')
          .child(bookId)
          .child(chapterId)
          .set({
        'purchasedAt': DateTime.now().millisecondsSinceEpoch,
        'price': price,
        'paymentMethod': 'demo', // In real app, this would be the actual method used
      });

      // Optional: Track purchase in analytics
      await _database
          .child('analytics')
          .child('purchases')
          .push()
          .set({
        'userId': currentUser.uid,
        'bookId': bookId,
        'chapterId': chapterId,
        'price': price,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      return true;
    } catch (e) {
      print('Error processing payment: $e');
      throw e;
    }
  }

  /// Get user's purchased chapters for a specific book
  static Future<List<String>> getUserPurchasedChapters(String bookId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final snapshot = await _database
          .child('users')
          .child(currentUser.uid)
          .child('purchasedChapters')
          .child(bookId)
          .get();

      if (!snapshot.exists) return [];

      final purchasedData = Map<String, dynamic>.from(snapshot.value as Map);
      return purchasedData.keys.toList();
    } catch (e) {
      print('Error getting purchased chapters: $e');
      return [];
    }
  }

  /// Get purchase details for a specific chapter
  static Future<Map<String, dynamic>?> getChapterPurchaseDetails(String bookId, String chapterId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final snapshot = await _database
          .child('users')
          .child(currentUser.uid)
          .child('purchasedChapters')
          .child(bookId)
          .child(chapterId)
          .get();

      if (!snapshot.exists) return null;

      return Map<String, dynamic>.from(snapshot.value as Map);
    } catch (e) {
      print('Error getting purchase details: $e');
      return null;
    }
  }

  /// Validate payment method (basic validation)
  static String? validatePaymentMethod(Map<String, String> paymentInfo) {
    final hasBank = paymentInfo['bankAccountNumber']?.isNotEmpty == true &&
        paymentInfo['ibanNumber']?.isNotEmpty == true;
    final hasJazzCash = paymentInfo['jazzCashNumber']?.isNotEmpty == true;
    final hasEasyPaisa = paymentInfo['easyPaisaNumber']?.isNotEmpty == true;

    if (!hasBank && !hasJazzCash && !hasEasyPaisa) {
      return 'Please provide at least one payment method';
    }

    // Validate IBAN format if provided
    if (paymentInfo['ibanNumber']?.isNotEmpty == true) {
      if (!RegExp(r'^PK\d{2}[A-Z]{4}\d{16}$').hasMatch(paymentInfo['ibanNumber']!)) {
        return 'Invalid IBAN format';
      }
    }

    // Validate phone numbers for JazzCash and EasyPaisa
    if (paymentInfo['jazzCashNumber']?.isNotEmpty == true) {
      if (!RegExp(r'^03\d{9}$').hasMatch(paymentInfo['jazzCashNumber']!)) {
        return 'Invalid JazzCash number format';
      }
    }

    if (paymentInfo['easyPaisaNumber']?.isNotEmpty == true) {
      if (!RegExp(r'^03\d{9}$').hasMatch(paymentInfo['easyPaisaNumber']!)) {
        return 'Invalid EasyPaisa number format';
      }
    }

    return null; // Valid
  }
}
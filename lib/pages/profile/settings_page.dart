import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _emailController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ibanController = TextEditingController();
  final _jazzCashController = TextEditingController();
  final _easyPaisaController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  bool _isLoading = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _accountNumberController.dispose();
    _ibanController.dispose();
    _jazzCashController.dispose();
    _easyPaisaController.dispose();
    super.dispose();
  }

  // Load existing user data from Firebase
  Future<void> _loadUserData() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      // Set email from Firebase Auth
      _emailController.text = currentUser.email ?? '';

      // Load payment info from Realtime Database
      final snapshot = await _database
          .child('users')
          .child(currentUser.uid)
          .child('paymentInfo')
          .get();

      if (snapshot.exists) {
        final paymentData = Map<String, dynamic>.from(snapshot.value as Map);

        setState(() {
          _accountNumberController.text = paymentData['bankAccountNumber'] ?? '';
          _ibanController.text = paymentData['ibanNumber'] ?? '';
          _jazzCashController.text = paymentData['jazzCashNumber'] ?? '';
          _easyPaisaController.text = paymentData['easyPaisaNumber'] ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  // Save payment information to Firebase
  Future<void> _saveSettings() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Validate inputs
      if (!_validateInputs()) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Update email in Firebase Auth if changed
      if (_emailController.text.trim() != currentUser.email) {
        await currentUser.updateEmail(_emailController.text.trim());
      }

      // Update payment information in Realtime Database
      await _database
          .child('users')
          .child(currentUser.uid)
          .child('paymentInfo')
          .update({
        'bankAccountNumber': _accountNumberController.text.trim(),
        'ibanNumber': _ibanController.text.trim(),
        'jazzCashNumber': _jazzCashController.text.trim(),
        'easyPaisaNumber': _easyPaisaController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Validate user inputs
  bool _validateInputs() {
    // Email validation
    if (_emailController.text.isEmpty) {
      _showErrorDialog('Please enter an email address');
      return false;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
      _showErrorDialog('Please enter a valid email address');
      return false;
    }

    // IBAN validation (basic Pakistani IBAN format)
    if (_ibanController.text.isNotEmpty) {
      if (!RegExp(r'^PK\d{2}[A-Z]{4}\d{16}$').hasMatch(_ibanController.text)) {
        _showErrorDialog('Please enter a valid Pakistani IBAN (e.g., PK36SCBL0000001123456702)');
        return false;
      }
    }

    // Phone number validation for JazzCash and EasyPaisa
    if (_jazzCashController.text.isNotEmpty) {
      if (!RegExp(r'^03\d{9}$').hasMatch(_jazzCashController.text)) {
        _showErrorDialog('Please enter a valid JazzCash number (03xxxxxxxxx)');
        return false;
      }
    }

    if (_easyPaisaController.text.isNotEmpty) {
      if (!RegExp(r'^03\d{9}$').hasMatch(_easyPaisaController.text)) {
        _showErrorDialog('Please enter a valid EasyPaisa number (03xxxxxxxxx)');
        return false;
      }
    }

    // Bank account number validation (basic numeric check)
    if (_accountNumberController.text.isNotEmpty) {
      if (!RegExp(r'^\d{10,16}$').hasMatch(_accountNumberController.text)) {
        _showErrorDialog('Please enter a valid bank account number (10-16 digits)');
        return false;
      }
    }

    return true;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Validation Error'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isInitializing
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text("Email", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: "example@email.com",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: true, // Email can be changed
            ),
            SizedBox(height: 16),
            Text("Account Number", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _accountNumberController,
              decoration: InputDecoration(
                hintText: "1234567890",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            Text("IBAN", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _ibanController,
              decoration: InputDecoration(
                hintText: "PK36SCBL0000001123456702",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            SizedBox(height: 16),
            Text("JazzCash Number", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _jazzCashController,
              decoration: InputDecoration(
                hintText: "03xxxxxxxxx",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            Text("EasyPaisa Number", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _easyPaisaController,
              decoration: InputDecoration(
                hintText: "03xxxxxxxxx",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              ),
              child: _isLoading
                  ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text("Save Settings"),
            ),
          ],
        ),
      ),
    );
  }
}
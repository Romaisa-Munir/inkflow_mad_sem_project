import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:inkflow_mad_sem_project/services/payment_service.dart';

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
  Map<String, dynamic>? _returnArgs;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkReturnRoute();
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

  // Check if we need to return to a specific route after saving
  void _checkReturnRoute() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _returnArgs = args;
      }
    });
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

      // Handle return navigation if specified
      if (_returnArgs != null) {
        final returnRoute = _returnArgs!['returnRoute'] as String?;
        final returnRouteArgs = _returnArgs!['returnArgs'] as Map<String, dynamic>?;

        if (returnRoute == '/book_reader' && returnRouteArgs != null) {
          Navigator.pushReplacementNamed(
            context,
            '/book_reader',
            arguments: returnRouteArgs,
          );
          return;
        }
      }

      Navigator.pop(context, true);
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

  // Logout function
  Future<void> _logout() async {
    try {
      // Show confirmation dialog
      bool? confirmLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmLogout == true) {
        // Sign out from Firebase
        await _auth.signOut();

        // Navigate to root and let AuthWrapper handle the redirect
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
              (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Validate user inputs using PaymentService
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

    // Use PaymentService validation
    final paymentInfo = {
      'bankAccountNumber': _accountNumberController.text.trim(),
      'ibanNumber': _ibanController.text.trim(),
      'jazzCashNumber': _jazzCashController.text.trim(),
      'easyPaisaNumber': _easyPaisaController.text.trim(),
    };

    final validationError = PaymentService.validatePaymentMethod(paymentInfo);
    if (validationError != null) {
      _showErrorDialog(validationError);
      return false;
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

  Widget _buildPaymentStatusIndicator() {
    return FutureBuilder<bool>(
      future: PaymentService.hasCompletePaymentInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        }

        final hasCompleteInfo = snapshot.data ?? false;

        return Container(
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hasCompleteInfo ? Colors.green[50] : Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasCompleteInfo ? Colors.green[200]! : Colors.orange[200]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                hasCompleteInfo ? Icons.check_circle : Icons.warning,
                color: hasCompleteInfo ? Colors.green[700] : Colors.orange[700],
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasCompleteInfo
                      ? 'Payment information is complete'
                      : 'Please complete at least one payment method',
                  style: TextStyle(
                    color: hasCompleteInfo ? Colors.green[700] : Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isReturnFlow = _returnArgs != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isReturnFlow ? "Complete Payment Setup" : "Settings"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (!isReturnFlow)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
        ],
      ),
      body: _isInitializing
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Return flow notice
            if (isReturnFlow) ...[
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.payment_outlined,
                      color: Colors.blue[700],
                      size: 32,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Payment Setup Required',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please complete at least one payment method to purchase chapters.',
                      style: TextStyle(
                        color: Colors.blue[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            // Payment status indicator
            _buildPaymentStatusIndicator(),

            Text("Email", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: "example@email.com",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: true,
            ),
            SizedBox(height: 16),

            // Bank Payment Section
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text(
                        "Bank Payment Details",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  Text("Account Number", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _accountNumberController,
                    decoration: InputDecoration(
                      hintText: "1234567890",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
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
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                    keyboardType: TextInputType.text,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Mobile Payment Section
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.phone_android, color: Colors.orange[700]),
                      SizedBox(width: 8),
                      Text(
                        "Mobile Payment Details",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  Text("JazzCash Number", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _jazzCashController,
                    decoration: InputDecoration(
                      hintText: "03xxxxxxxxx",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
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
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Payment requirement note
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Complete at least one payment method (bank or mobile) to purchase chapters.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: isReturnFlow ? Colors.orange : Theme.of(context).colorScheme.inversePrimary,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isReturnFlow ? Icons.check : Icons.save),
                  SizedBox(width: 8),
                  Text(
                    isReturnFlow ? "Complete Setup & Continue" : "Save Settings",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Logout Button (only if not return flow)
            if (!isReturnFlow) ...[
              OutlinedButton.icon(
                onPressed: _logout,
                icon: Icon(Icons.logout, color: Colors.red),
                label: Text("Logout", style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],

            // Cancel Button (only if return flow)
            if (isReturnFlow) ...[
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
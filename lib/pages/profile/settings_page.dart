import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
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
              // Email validation pattern
              onChanged: (text) {
                // You can add custom validation here if needed
              },
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
              // You can add number validation here
            ),
            SizedBox(height: 16),
            Text("IBAN", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _ibanController,
              decoration: InputDecoration(
                hintText: "IBAN Number",
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
              onPressed: () {
                // Handle the save operation
                // Ideally, save the settings here (e.g., to a database or local storage)
                Navigator.pop(context); // Go back to the Profile page
              },
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.inversePrimary,),
              child: Text("Save Settings"),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:brainu/screens/language_selection.dart';

void main() {
  runApp(BrainUApp());
}

class BrainUApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BrainU App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PermissionRequestScreen(),
    );
  }
}

class PermissionRequestScreen extends StatefulWidget {
  @override
  _PermissionRequestScreenState createState() => _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends State<PermissionRequestScreen> {
  @override
  void initState() {
    super.initState();
    _requestMicrophonePermission();
  }

  Future<void> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();

    if (status.isGranted) {
      _navigateToLanguageSelection();
    } else if (status.isDenied || status.isPermanentlyDenied) {
      _showPermissionError();
    }
  }

  void _navigateToLanguageSelection() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LanguageSelectionScreen()),
    );
  }

  void _showPermissionError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Required'),
        content: Text(
            'Microphone access is required to use this feature. Please enable it in your settings.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _requestMicrophonePermission(); // Retry permission request
            },
            child: Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(), // Display a loading indicator while requesting permissions
      ),
    );
  }
}

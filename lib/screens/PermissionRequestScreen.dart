// screens/PermissionRequestScreen.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../Authentication/login_page.dart';
import '../widgets/app_loader.dart'; // ✅ NEW: import loader

class PermissionRequestScreen extends StatefulWidget {
  @override
  _PermissionRequestScreenState createState() =>
      _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends State<PermissionRequestScreen> {
  bool _isLoading = true; // ✅ NEW: track loading state

  @override
  void initState() {
    super.initState();
    _requestMicrophonePermission();
  }

  Future<void> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();

    if (status.isGranted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => LoginPage()));
    } else {
      setState(() => _isLoading = false); // ✅ hide loader if denied
      _showPermissionError();
    }
  }

  void _showPermissionError() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Permission Required'),
        content: Text(
            'Microphone access is required to use this feature. Please enable it in your settings.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isLoading = true); // ✅ show loader again
              _requestMicrophonePermission();
            },
            child: Text('Retry'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: _isLoading
              ? const AppLoader(
                  // ✅ professional loader
                  message: "Requesting microphone permission...",
                  style: LoaderStyle.circle,
                )
              : const Text("Permission not granted"),
        ),
      );
}

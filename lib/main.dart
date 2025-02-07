import 'package:brainu/Authentication/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/l10n.dart';

import 'screens/LevelSelectionScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? storedUid = prefs.getString('uid');

  runApp(BrainUApp(storedUid: storedUid));
}

class BrainUApp extends StatefulWidget {
  final String? storedUid;

  BrainUApp({required this.storedUid});

  static void setLocale(BuildContext context, Locale newLocale) {
    _BrainUAppState? state = context.findAncestorStateOfType<_BrainUAppState>();
    state?.setLocale(newLocale);
  }

  @override
  _BrainUAppState createState() => _BrainUAppState();
}

class _BrainUAppState extends State<BrainUApp> {
  Locale _locale = Locale('en'); // Default to English

  @override
  void initState() {
    super.initState();
    _fetchUserLanguage();
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  Future<void> _fetchUserLanguage() async {
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        String language = userDoc.get("language") ?? "en";

        // Mapping languages properly
        Map<String, String> languageMap = {
          "Hindi": "hi",
          "English": "en",
          "Spanish": "es",
          "French": "fr",
        };

        String mappedLanguage = languageMap[language] ?? language;

        setLocale(Locale(mappedLanguage));
        print("Fetched language: $language, Mapped to: $mappedLanguage");
      }
    } catch (e) {
      print("Error fetching user language: $e");
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BrainU App',
      theme: ThemeData(primarySwatch: Colors.blue),
      locale: _locale,
      supportedLocales: S.delegate.supportedLocales,
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: widget.storedUid != null ? LevelSelectionScreen() : LoginPage(),
    );
  }
}

class PermissionRequestScreen extends StatefulWidget {
  @override
  _PermissionRequestScreenState createState() =>
      _PermissionRequestScreenState();
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
      MaterialPageRoute(builder: (context) => LoginPage()),
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
        child: CircularProgressIndicator(),
      ),
    );
  }
}

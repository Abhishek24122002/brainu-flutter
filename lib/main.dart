import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'generated/l10n.dart';
import 'managers/language_manager.dart';
import 'managers/trophy_manager.dart';
import 'screens/LevelSelectionScreen.dart';
import 'Authentication/login_page.dart';
import 'screens/PermissionRequestScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Hive
  await Hive.initFlutter();

  // Get current Firebase user (if any)
  final user = FirebaseAuth.instance.currentUser;

  // Initialize LanguageManager with userId ('' if not logged in yet)
  final languageManager = LanguageManager(userId: user?.uid ?? '');
  await languageManager.init();

  // Initialize TrophyManager with userId ('' if not logged in yet)
  final trophyManager = TrophyManager(userId: user?.uid ?? '');
  await trophyManager.loadFromHive(); // load local trophies
  if (user != null)
    await trophyManager.loadFromFirebase(); // sync with Firestore

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: languageManager),
        ChangeNotifierProvider.value(value: trophyManager),
      ],
      child: BrainUApp(),
    ),
  );
}

class BrainUApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageManager>(
      builder: (_, langManager, __) {
        return ScreenUtilInit(
          designSize: Size(1440, 1024),
          builder: (_, __) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'BrainU App',
              theme: ThemeData(primarySwatch: Colors.brown),
              locale: langManager.currentLocale,
              supportedLocales: S.delegate.supportedLocales,
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: _getHomeScreen(),
            );
          },
        );
      },
    );
  }

  Widget _getHomeScreen() {
    final user = FirebaseAuth.instance.currentUser;

    // If user already signed in → go to main LevelSelectionScreen
    if (user != null) return LevelSelectionScreen();

    // If not signed in → first request permission → then LoginPage
    return PermissionRequestScreen();
  }
}

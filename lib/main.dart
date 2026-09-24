import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Log app open for analytics
    FirebaseAnalytics.instance.logAppOpen();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    debugPrint('Did you forget to run flutterfire configure?');
  }

  runApp(const ProviderScope(child: VidKwaiiApp()));
}

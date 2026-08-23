import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'presentation/home_shell.dart';

class MediaHubApp extends StatelessWidget {
  const MediaHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const HomeShell(),
    );
  }
}

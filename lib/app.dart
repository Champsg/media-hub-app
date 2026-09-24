import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'logic/providers.dart';
import 'presentation/home_shell.dart';

class VidKwaiiApp extends ConsumerWidget {
  const VidKwaiiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Starts the settings controller, which also looks up the backend address
    // from remote config (see AppConfigController.refreshRemote).
    ref.watch(appConfigControllerProvider);

    // Warm up the ad SDK and preload an ad while the user is on the home
    // screen, instead of waiting until the first download tap.
    ref.watch(adServiceProvider);

    return MaterialApp(
      title: 'VidKwaii',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const HomeShell(),
    );
  }
}

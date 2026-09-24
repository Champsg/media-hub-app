import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class ForceUpdateWrapper extends StatefulWidget {
  final Widget child;

  const ForceUpdateWrapper({super.key, required this.child});

  @override
  State<ForceUpdateWrapper> createState() => _ForceUpdateWrapperState();
}

class _ForceUpdateWrapperState extends State<ForceUpdateWrapper> {
  bool _isLoading = true;
  bool _updateRequired = false;
  String _updateUrl = '';

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      await remoteConfig.fetchAndActivate();

      final requiredVersion = remoteConfig.getString('force_update_version');
      _updateUrl = remoteConfig.getString(Platform.isIOS ? 'ios_update_url' : 'android_update_url');

      if (requiredVersion.isNotEmpty) {
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (_isUpdateRequired(currentVersion, requiredVersion)) {
          setState(() {
            _updateRequired = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching remote config: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isUpdateRequired(String currentVersion, String requiredVersion) {
    final currentParts = currentVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final requiredParts = requiredVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < requiredParts.length; i++) {
      if (i >= currentParts.length) return true;
      if (requiredParts[i] > currentParts[i]) return true;
      if (requiredParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_updateRequired) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.system_update, size: 80, color: Colors.blueAccent),
                const SizedBox(height: 24),
                const Text(
                  'Update Required',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'A new version of the app is available. Please update to continue using the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    if (_updateUrl.isNotEmpty) {
                      final uri = Uri.parse(_updateUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Update Now'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}

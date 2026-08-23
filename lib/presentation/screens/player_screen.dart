import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';

/// In-app player with speed controls, fullscreen and keep-screen-on.
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.path, required this.title});

  final String path;
  final String title;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _keepScreenOn = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.file(File(widget.path));
    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        allowPlaybackSpeedChanging: true,
        playbackSpeeds: const [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0],
        allowFullScreen: true,
        deviceOrientationsAfterFullScreen: const [
          DeviceOrientation.portraitUp,
        ],
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          bufferedColor: AppColors.border,
          backgroundColor: AppColors.surfaceHigh,
        ),
      );
      setState(() {
        _videoController = controller;
        _chewieController = chewie;
      });
      await _applyKeepScreenOn(true);
    } catch (e) {
      setState(() => _error = '$e');
      controller.dispose();
    }
  }

  Future<void> _applyKeepScreenOn(bool enabled) async {
    setState(() => _keepScreenOn = enabled);
    if (enabled) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: AppStrings.keepScreenOn,
            onPressed: () => _applyKeepScreenOn(!_keepScreenOn),
            icon: Icon(
              _keepScreenOn
                  ? Icons.screen_lock_portrait_rounded
                  : Icons.screen_lock_portrait_outlined,
              color: _keepScreenOn
                  ? AppColors.secondary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.danger,
                      size: 44,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Could not play this file\n$_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : _chewieController == null
                ? const CircularProgressIndicator()
                : Chewie(controller: _chewieController!),
      ),
    );
  }
}

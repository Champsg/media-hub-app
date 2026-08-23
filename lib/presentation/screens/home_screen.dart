import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/download_task.dart';
import '../../logic/extract_controller.dart';
import '../../logic/providers.dart';
import '../widgets/clipboard_banner.dart';
import '../widgets/download_tile.dart';
import '../widgets/extract_result_card.dart';
import '../widgets/url_input_bar.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void> _extract(String url) async {
    FocusScope.of(context).unfocus();
    await ref.read(extractControllerProvider).extract(url);
  }

  @override
  Widget build(BuildContext context) {
    final extract = ref.watch(extractControllerProvider);
    final downloads = ref.watch(downloadControllerProvider);
    final active = downloads.activeTasks;
    final failed = downloads.tasks
        .where((task) => task.status == DownloadStatus.failed)
        .toList();
    final completed = downloads.tasks
        .where((task) => task.status == DownloadStatus.completed)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
              child: Row(
                children: [
                  const AppLogo(),
                  const Spacer(),
                  IconButton(
                    tooltip: AppStrings.settings,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.settings_rounded),
                  ),
                ],
              ),
            ),
            const ClipboardBanner(),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: UrlInputBar(
                onSubmit: _extract,
                loading: extract.state.isLoading,
              ),
            ),
            _buildExtractSection(extract),
            const SizedBox(height: 20),
            const SectionHeader(title: AppStrings.activeDownloads),
            if (active.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  AppStrings.noActiveDownloads,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              for (final task in active)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: DownloadTile(task: task),
                ),
            if (failed.isNotEmpty) ...[
              const SizedBox(height: 18),
              const SectionHeader(title: 'Failed downloads'),
              for (final task in failed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: DownloadTile(task: task),
                ),
            ],
            const SizedBox(height: 18),
            const SectionHeader(title: AppStrings.recentDownloads),
            if (completed.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: EmptyState(
                  icon: Icons.download_done_rounded,
                  title: 'No downloads yet',
                  subtitle:
                      'Paste a link above or use the Browser to grab media.',
                ),
              )
            else
              for (final task in completed.take(3))
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: DownloadTile(task: task),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtractSection(ExtractController extract) {
    return extract.state.when(
      data: (result) => result == null
          ? const SizedBox.shrink()
          : ExtractResultCard(result: result),
      loading: () => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: GlassCard(
          child: Column(
            children: const [
              SizedBox(height: 44),
              CircularProgressIndicator(),
              SizedBox(height: 14),
              Text(
                'Resolving & extracting metadata…',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              SizedBox(height: 44),
            ],
          ),
        ),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: GlassCard(
          borderColor: AppColors.danger.withOpacity(0.5),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.danger,
                size: 34,
              ),
              const SizedBox(height: 10),
              const Text(
                'Extraction failed',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: extract.lastUrl == null
                    ? null
                    : () => extract.extract(extract.lastUrl!),
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

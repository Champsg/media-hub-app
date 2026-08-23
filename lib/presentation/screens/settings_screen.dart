import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/section_header.dart';
import '../../logic/app_config_controller.dart';
import '../../logic/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _initialized = false;
  bool _checking = false;
  bool? _healthy;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configController = ref.watch(appConfigControllerProvider);
    if (!_initialized && configController.loaded) {
      _initialized = true;
      _urlController.text = configController.config.baseUrl;
    }
    final config = configController.config;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.settings,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          const SectionHeader(title: 'Server'),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.serverUrl,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    hintText: 'http://10.0.2.2:8000',
                    prefixIcon: Icon(Icons.dns_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          await configController
                              .setBaseUrl(_urlController.text);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Server URL saved'),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Save',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _checking ? null : () => _check(),
                        child: _checking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Test'),
                      ),
                    ),
                  ],
                ),
                if (_healthy != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        _healthy!
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        size: 18,
                        color: _healthy!
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _healthy! ? 'Backend reachable' : 'Backend unreachable',
                        style: TextStyle(
                          fontSize: 13,
                          color: _healthy!
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Downloads'),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      AppStrings.parallelChunks,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${config.parallelChunks}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: config.parallelChunks.toDouble(),
                  min: 1,
                  max: 8,
                  divisions: 7,
                  label: '${config.parallelChunks}',
                  onChanged: (value) =>
                      configController.setParallelChunks(value.round()),
                ),
                const Text(
                  'Parallel chunked downloads speed up large files on servers '
                  'that support range requests.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'About'),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    AppLogo(compact: true),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Media Hub',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'v1.0.0 · Flutter + FastAPI',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Universal media grabber with an HLS segment stitcher, smart '
                  'browser sniffer and a WhatsApp status vault.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _healthy = null;
    });
    final healthy = await ref.read(apiClientProvider).health();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _healthy = healthy;
    });
  }
}

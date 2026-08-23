import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/models/status_item.dart';
import '../../logic/providers.dart';
import '../../logic/vault_controller.dart';
import 'player_screen.dart';

class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vault = ref.watch(vaultControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.vault,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (vault.treeUri != null)
            IconButton(
              tooltip: 'Disconnect',
              onPressed: () => ref.read(vaultControllerProvider).disconnect(),
              icon: const Icon(Icons.link_off_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          if (vault.error != null) _ErrorBanner(message: vault.error!),
          if (vault.scanning) const LinearProgressIndicator(minHeight: 3),
          Expanded(child: _buildBody(context, ref, vault)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    VaultController vault,
  ) {
    if (vault.treeUri == null) {
      return EmptyState(
        icon: Icons.folder_copy_outlined,
        title: 'Connect your WhatsApp folder',
        subtitle:
            'Pick the folder that contains your statuses (e.g. WhatsApp/Media/'
            '.Statuses). Everything stays private on your device.',
        action: FilledButton.icon(
          onPressed: () => ref.read(vaultControllerProvider).pickAndScan(),
          icon: const Icon(Icons.folder_open_rounded),
          label: const Text('Choose folder'),
        ),
      );
    }
    if (vault.scanning) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text(
              'Scanning for statuses…',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    if (vault.items.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No statuses found',
        subtitle:
            'Make sure the picked folder contains media files (JPG/PNG/MP4).',
        action: OutlinedButton.icon(
          onPressed: () => ref.read(vaultControllerProvider).pickAndScan(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Rescan'),
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Row(
            children: [
              Text(
                '${vault.items.length} statuses found',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _saveAll(context, ref),
                icon: const Icon(Icons.download_done_rounded, size: 18),
                label: const Text(
                  AppStrings.downloadAll,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.86,
            ),
            itemCount: vault.items.length,
            itemBuilder: (context, index) {
              final item = vault.items[index];
              return _StatusCard(
                item: item,
                saving: vault.saving.contains(item.uri),
                onSave: () => _save(context, ref, item),
                onPreview: () => _preview(context, ref, item),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    VaultStatusItem item,
  ) async {
    final controller = ref.read(vaultControllerProvider);
    final path = await controller.save(item);
    if (!context.mounted) return;
    if (path != null) {
      ref.read(libraryControllerProvider).refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to Vault: ${item.name}')),
      );
    }
  }

  Future<void> _saveAll(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(vaultControllerProvider);
    await controller.saveAll();
    ref.read(libraryControllerProvider).refresh();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Statuses saved to the Vault')),
      );
    }
  }

  Future<void> _preview(
    BuildContext context,
    WidgetRef ref,
    VaultStatusItem item,
  ) async {
    final controller = ref.read(vaultControllerProvider);
    await controller.preview(item);
    if (!context.mounted) return;
    final path = controller.previewPath;
    controller.clearPreview();
    if (path == null) return;
    if (item.isImage) {
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(File(path), fit: BoxFit.contain),
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlayerScreen(path: path, title: item.name),
        ),
      );
    }
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.item,
    required this.saving,
    required this.onSave,
    required this.onPreview,
  });

  final VaultStatusItem item;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final color = item.isImage
        ? AppColors.secondary
        : item.isVideo
            ? AppColors.primary
            : item.isAudio
                ? AppColors.accent
                : AppColors.textSecondary;
    final icon = item.isImage
        ? Icons.image_rounded
        : item.isVideo
            ? Icons.play_circle_fill_rounded
            : item.isAudio
                ? Icons.music_note_rounded
                : Icons.insert_drive_file_rounded;

    return GlassCard(
      padding: const EdgeInsets.all(12),
      radius: 18,
      onTap: onPreview,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.surfaceHigh,
                    color.withOpacity(0.22),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, size: 40, color: color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  Formatters.bytes(item.size),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Save to Vault',
                onPressed: saving ? null : onSave,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.download_rounded,
                        size: 20,
                        color: AppColors.success,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withOpacity(0.4)),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 12, color: AppColors.danger),
      ),
    );
  }
}

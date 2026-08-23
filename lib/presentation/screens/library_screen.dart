import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/library_item.dart';
import '../../logic/providers.dart';
import '../widgets/media_card.dart';
import 'player_screen.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppStrings.library,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.read(libraryControllerProvider).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: library.loading && library.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : library.items.isEmpty
              ? EmptyState(
                  icon: Icons.video_library_outlined,
                  title: 'Your library is empty',
                  subtitle: AppStrings.emptyLibrary,
                  action: FilledButton.icon(
                    onPressed: () =>
                        ref.read(libraryControllerProvider).refresh(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(libraryControllerProvider).refresh(),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: library.items.length,
                    itemBuilder: (context, index) {
                      final item = library.items[index];
                      return MediaCard(
                        item: item,
                        onTap: () => _open(context, ref, item),
                        onLongPress: () => _showActions(context, ref, item),
                      );
                    },
                  ),
                ),
    );
  }

  void _open(BuildContext context, WidgetRef ref, LibraryItem item) {
    if (item.kind == MediaKind.video || item.kind == MediaKind.audio) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlayerScreen(path: item.path, title: item.name),
        ),
      );
    } else {
      _showActions(context, ref, item);
    }
  }

  Future<void> _showActions(
    BuildContext context,
    WidgetRef ref,
    LibraryItem item,
  ) async {
    final controller = ref.read(libraryControllerProvider);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.kind == MediaKind.video ||
                item.kind == MediaKind.audio)
              ListTile(
                leading: const Icon(Icons.play_circle_outline_rounded),
                title: const Text('Play'),
                onTap: () => Navigator.pop(sheetContext, 'play'),
              ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              onTap: () => Navigator.pop(sheetContext, 'share'),
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
              ),
              title: const Text(
                'Delete',
                style: TextStyle(color: AppColors.danger),
              ),
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case 'play':
        _open(context, ref, item);
        break;
      case 'share':
        await controller.share(item);
        break;
      case 'delete':
        await controller.delete(item);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted ${item.name}')),
          );
        }
        break;
    }
  }
}

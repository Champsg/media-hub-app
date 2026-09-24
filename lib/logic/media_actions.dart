import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/download_task.dart';
import 'providers.dart';

enum ServerJobKind { merged, audio }

/// Runs a server-side job (FFmpeg merge or audio extraction), shows a blocking
/// progress dialog while it works, then starts the chunked download of the
/// produced file.
Future<DownloadTask?> startServerJob(
  BuildContext context,
  WidgetRef ref, {
  required String url,
  required String title,
  required ServerJobKind kind,
}) async {
  final label = kind == ServerJobKind.merged
      ? 'Merging video + audio on server…'
      : 'Extracting audio on server…';
  final api = ref.read(apiClientProvider);
  final downloads = ref.read(downloadControllerProvider);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ServerJobDialog(label: label),
  );

  try {
    final file = kind == ServerJobKind.merged
        ? await api.mergeMedia(url)
        : await api.extractAudio(url);
    final fileName =
        file.filename.isNotEmpty ? file.filename : '$title.mp4';
    final task = await downloads.start(url: file.url, fileName: fileName);
    ref.read(libraryControllerProvider).refresh();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download started')),
      );
    }
    return task;
  } catch (e) {
    if (context.mounted) {
      final message = '$e';
      final hint = message.contains('404')
          ? '\nThe backend needs the latest update - redeploy it on Render.'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server job failed: $message$hint')),
      );
    }
    return null;
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

class _ServerJobDialog extends StatelessWidget {
  const _ServerJobDialog({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

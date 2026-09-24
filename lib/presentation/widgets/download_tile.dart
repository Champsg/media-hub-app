import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/download_task.dart';
import '../../logic/download_controller.dart';
import '../../logic/providers.dart';

class DownloadTile extends ConsumerWidget {
  const DownloadTile({super.key, required this.task});

  final DownloadTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(downloadControllerProvider);
    final status = task.status;
    final progress = status == DownloadStatus.completed
        ? 1.0
        : task.totalBytes > 0
            ? (task.receivedBytes / task.totalBytes).clamp(0.0, 1.0)
            : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _colorFor(status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _iconFor(status),
                  color: _colorFor(status),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  task.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _StatusChip(status: status),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppColors.border.withValues(alpha: 0.3),
              color: _colorFor(status),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${Formatters.bytes(task.receivedBytes)} / '
                '${Formatters.bytes(task.totalBytes)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (task.speedBytesPerSecond > 0)
                Text(
                  Formatters.speed(task.speedBytesPerSecond),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              const SizedBox(width: 10),
              if (task.toProgress().eta != null)
                Text(
                  'ETA ${Formatters.duration(task.toProgress().eta!.inSeconds)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          if (task.error != null) ...[
            const SizedBox(height: 8),
            Text(
              task.error!,
              style: const TextStyle(fontSize: 12, color: AppColors.danger),
            ),
          ],
          if (_actionsFor(status).isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (final action in _actionsFor(status)) ...[
                  _ActionButton(
                    label: action.label,
                    icon: action.icon,
                    color: action.color,
                    onPressed: () => action.onPressed(controller),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.queued:
        return Icons.hourglass_top_rounded;
      case DownloadStatus.running:
        return Icons.downloading_rounded;
      case DownloadStatus.merging:
        return Icons.merge_rounded;
      case DownloadStatus.paused:
        return Icons.pause_rounded;
      case DownloadStatus.completed:
        return Icons.check_rounded;
      case DownloadStatus.failed:
        return Icons.close_rounded;
      case DownloadStatus.canceled:
        return Icons.block_rounded;
    }
  }

  Color _colorFor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.running:
      case DownloadStatus.queued:
        return AppColors.primary;
      case DownloadStatus.merging:
        return AppColors.secondary;
      case DownloadStatus.completed:
        return AppColors.success;
      case DownloadStatus.failed:
        return AppColors.danger;
      case DownloadStatus.paused:
        return AppColors.warning;
      case DownloadStatus.canceled:
        return AppColors.textFaint;
    }
  }

  List<_TaskAction> _actionsFor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.running:
      case DownloadStatus.queued:
        return [
          _TaskAction(
            label: AppStrings.pause,
            icon: Icons.pause_rounded,
            color: AppColors.warning,
            onPressed: (c) => c.pause(task.id),
          ),
          _TaskAction(
            label: AppStrings.cancel,
            icon: Icons.close_rounded,
            color: AppColors.textSecondary,
            onPressed: (c) => c.cancel(task.id),
          ),
        ];
      case DownloadStatus.merging:
        return [
          _TaskAction(
            label: AppStrings.cancel,
            icon: Icons.close_rounded,
            color: AppColors.textSecondary,
            onPressed: (c) => c.cancel(task.id),
          ),
        ];
      case DownloadStatus.paused:
        return [
          _TaskAction(
            label: AppStrings.resume,
            icon: Icons.play_arrow_rounded,
            color: AppColors.success,
            onPressed: (c) => c.resume(task.id),
          ),
          _TaskAction(
            label: AppStrings.cancel,
            icon: Icons.close_rounded,
            color: AppColors.textSecondary,
            onPressed: (c) => c.cancel(task.id),
          ),
        ];
      case DownloadStatus.failed:
        return [
          _TaskAction(
            label: AppStrings.retry,
            icon: Icons.refresh_rounded,
            color: AppColors.primary,
            onPressed: (c) => c.retry(task.id),
          ),
          _TaskAction(
            label: 'Remove',
            icon: Icons.delete_outline_rounded,
            color: AppColors.textSecondary,
            onPressed: (c) => c.remove(task.id),
          ),
        ];
      case DownloadStatus.completed:
      case DownloadStatus.canceled:
        return [
          _TaskAction(
            label: 'Remove',
            icon: Icons.close_rounded,
            color: AppColors.textSecondary,
            onPressed: (c) => c.remove(task.id),
          ),
        ];
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final DownloadStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      DownloadStatus.queued => ('Queued', AppColors.warning),
      DownloadStatus.running => ('Downloading', AppColors.primary),
      DownloadStatus.merging => ('Merging...', AppColors.secondary),
      DownloadStatus.paused => ('Paused', AppColors.warning),
      DownloadStatus.completed => ('Downloaded', AppColors.success),
      DownloadStatus.failed => ('Failed', AppColors.danger),
      DownloadStatus.canceled => ('Canceled', AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _TaskAction {
  const _TaskAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final void Function(DownloadController controller) onPressed;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: color),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          backgroundColor: color.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

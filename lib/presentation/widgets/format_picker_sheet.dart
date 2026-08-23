import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/extract_result.dart';

/// Bottom sheet that lets the user pick a format from an extracted media.
Future<MediaFormat?> showFormatPickerSheet(
  BuildContext context,
  ExtractResult result,
) {
  return showModalBottomSheet<MediaFormat>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _FormatSheet(result: result),
  );
}

class _FormatSheet extends StatefulWidget {
  const _FormatSheet({required this.result});

  final ExtractResult result;

  @override
  State<_FormatSheet> createState() => _FormatSheetState();
}

class _FormatSheetState extends State<_FormatSheet> {
  MediaFormat? _selected;

  @override
  void initState() {
    super.initState();
    final recommended = widget.result.recommendedFormatId;
    if (recommended != null) {
      for (final format in widget.result.formats) {
        if (format.formatId == recommended) {
          _selected = format;
          break;
        }
      }
    }
    _selected ??= widget.result.formats.isNotEmpty
        ? widget.result.formats.first
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final formats = widget.result.formats;
    return SizedBox(
      height: height * 0.68,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.result.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formats.length} format${formats.length == 1 ? '' : 's'} available',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: formats.isEmpty
                ? const Center(
                    child: Text(
                      'No downloadable formats were found.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    itemCount: formats.length,
                    itemBuilder: (context, index) {
                      final format = formats[index];
                      final selected = _selected?.formatId == format.formatId;
                      final recommended =
                          format.formatId == widget.result.recommendedFormatId;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Material(
                          color: selected
                              ? AppColors.primary.withOpacity(0.14)
                              : AppColors.surfaceHigh.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => setState(() => _selected = format),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selected
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_off_rounded,
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.textFaint,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          format.displayLabel,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        if (format.codecLabel.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '${format.codecLabel} · ${format.protocol}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (recommended)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.brandGradient,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'Best',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selected == null
                      ? null
                      : () => Navigator.of(context).pop(_selected),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Download ${_selected?.displayLabel ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

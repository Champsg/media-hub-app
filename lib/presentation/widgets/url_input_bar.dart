import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';

class UrlInputBar extends StatefulWidget {
  const UrlInputBar({
    super.key,
    required this.onSubmit,
    this.loading = false,
  });

  final ValueChanged<String> onSubmit;
  final bool loading;

  @override
  State<UrlInputBar> createState() => _UrlInputBarState();
}

class _UrlInputBarState extends State<UrlInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.isEmpty) return;
    _controller.text = text.trim();
    _focusNode.requestFocus();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: AppStrings.urlHint,
                prefixIcon: const Icon(
                  Icons.link_rounded,
                  color: AppColors.textFaint,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.content_paste_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: _paste,
                  tooltip: AppStrings.paste,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: widget.loading ? null : _submit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: widget.loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    AppStrings.extract,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
    );
  }
}

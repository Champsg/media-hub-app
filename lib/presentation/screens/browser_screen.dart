import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/url_utils.dart';
import '../../data/models/download_task.dart';
import '../../data/services/web_sniffer.dart';
import '../../logic/providers.dart';
import '../widgets/floating_download_button.dart';
import '../widgets/format_picker_sheet.dart';

class BrowserScreen extends ConsumerStatefulWidget {
  const BrowserScreen({super.key});

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen> {
  late final WebViewController _webController;
  int _progress = 0;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..addJavaScriptChannel(
        WebSniffer.channelName,
        onMessageReceived: (message) => ref
            .read(browserControllerProvider)
            .handleJsMessage(message.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            ref.read(browserControllerProvider).setUrl(url);
            setState(() => _lastError = null);
          },
          onProgress: (progress) => setState(() => _progress = progress),
          onPageFinished: (_) {
            setState(() => _progress = 100);
            _injectSniffer();
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? false) {
              setState(() => _lastError = error.description);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.google.com'));
  }

  Future<void> _injectSniffer() async {
    try {
      await _webController.runJavaScript(WebSniffer.injectionScript);
      ref.read(browserControllerProvider).setSnifferActive(true);
    } catch (_) {
      // Page may still be navigating; the sniffer is re-injected per page.
    }
  }

  Future<void> _goBack() async {
    try {
      await _webController.goBack();
    } catch (_) {}
  }

  Future<void> _goForward() async {
    try {
      await _webController.goForward();
    } catch (_) {}
  }

  Future<void> _reload() async {
    await _webController.reload();
  }

  @override
  Widget build(BuildContext context) {
    final browser = ref.watch(browserControllerProvider);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: _UrlChip(url: browser.currentUrl ?? 'Browser'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            tooltip: 'Forward',
            onPressed: _goForward,
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
          IconButton(
            tooltip: 'Reload',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (browser.media.isNotEmpty)
            IconButton(
              tooltip: 'Clear sniffed media',
              onPressed: () =>
                  ref.read(browserControllerProvider).clearMedia(),
              icon: const Icon(Icons.cleaning_services_rounded),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_progress < 100)
                LinearProgressIndicator(
                  value: _progress / 100,
                  minHeight: 2,
                ),
              Expanded(
                child: _lastError != null
                    ? _BrowserError(
                        message: _lastError!,
                        onRetry: () {
                          setState(() => _lastError = null);
                          _reload();
                        },
                      )
                    : WebViewWidget(controller: _webController),
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 20,
            child: FloatingDownloadButton(
              count: browser.media.length,
              visible: browser.media.isNotEmpty,
              onTap: () => _showSniffedSheet(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSniffedSheet(BuildContext context) async {
    final items = ref.read(browserControllerProvider).media.toList();
    if (items.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.of(sheetContext).size.height * 0.62,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                'Sniffed media on this page',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Material(
                    color: AppColors.surfaceHigh.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(14),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      leading: const Icon(
                        Icons.movie_rounded,
                        color: AppColors.secondary,
                      ),
                      title: Text(
                        item.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        UrlUtils.displayHost(item.url),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: FilledButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          _handleSniffed(item);
                        },
                        child: const Text(
                          'Grab',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSniffed(SniffedMedia item) async {
    final downloads = ref.read(downloadControllerProvider);
    if (UrlUtils.isDirectMediaUrl(item.url)) {
      await downloads.start(
        url: item.url,
        fileName: _fileNameFor(item),
        isHls: UrlUtils.looksLikeHls(item.url),
      );
      ref.read(libraryControllerProvider).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download started')),
        );
      }
      return;
    }

    final extract = ref.read(extractControllerProvider);
    await extract.extract(item.url);
    if (!mounted) return;
    final result = extract.state.valueOrNull;
    if (result != null && result.formats.isNotEmpty) {
      final format = await showFormatPickerSheet(context, result);
      if (format == null) return;
      await downloads.start(
        url: format.url,
        fileName: result.suggestedFilename ?? _fileNameFor(item),
        isHls: format.isHls,
      );
      ref.read(libraryControllerProvider).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download started')),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            extract.state.hasError
                ? 'Could not extract this media: ${extract.state.error}'
                : 'No playable media found at this URL.',
          ),
        ),
      );
    }
  }

  String _fileNameFor(SniffedMedia item) {
    final uri = Uri.tryParse(item.url);
    final lastSegment = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : '';
    if (lastSegment.isNotEmpty && lastSegment.contains('.')) {
      return lastSegment;
    }
    final host = uri?.host ?? 'media';
    return '${host}_${item.detectedAt.millisecondsSinceEpoch}.mp4';
  }
}

class _UrlChip extends StatelessWidget {
  const _UrlChip({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final host = UrlUtils.displayHost(url);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        host,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _BrowserError extends StatelessWidget {
  const _BrowserError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 44,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 14),
            const Text(
              'Could not load this page',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

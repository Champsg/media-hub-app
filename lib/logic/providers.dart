import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/api_config.dart';
import '../data/repositories/media_repository.dart';
import '../data/services/api_client.dart';
import '../data/services/downloader_service.dart';
import '../data/services/whatsapp_vault_service.dart';
import 'app_config_controller.dart';
import 'browser_controller.dart';
import 'clipboard_controller.dart';
import 'download_controller.dart';
import 'extract_controller.dart';
import 'library_controller.dart';
import 'vault_controller.dart';

/// Mutable runtime settings (base URL, chunk count).
final apiConfigProvider = Provider<ApiConfig>((ref) => ApiConfig());

/// Persisted app settings.
final appConfigControllerProvider =
    ChangeNotifierProvider<AppConfigController>((ref) {
  final controller = AppConfigController(ref.watch(apiConfigProvider));
  controller.load();
  return controller;
});

final apiClientProvider =
    Provider<ApiClient>((ref) => ApiClient(ref.watch(apiConfigProvider)));

final downloaderServiceProvider = Provider<DownloaderService>((ref) {
  final service = DownloaderService();
  ref.onDispose(service.dispose);
  return service;
});

final mediaRepositoryProvider = Provider<MediaRepository>(
  (ref) => MediaRepository(
    api: ref.watch(apiClientProvider),
    downloader: ref.watch(downloaderServiceProvider),
  ),
);

final extractControllerProvider = ChangeNotifierProvider<ExtractController>(
  (ref) => ExtractController(ref.watch(mediaRepositoryProvider)),
);

final downloadControllerProvider = ChangeNotifierProvider<DownloadController>(
  (ref) => DownloadController(
    repository: ref.watch(mediaRepositoryProvider),
    downloader: ref.watch(downloaderServiceProvider),
    config: ref.watch(apiConfigProvider),
  ),
);

final libraryControllerProvider = ChangeNotifierProvider<LibraryController>(
  (ref) {
    final controller = LibraryController();
    Future.microtask(controller.refresh);
    return controller;
  },
);

final clipboardControllerProvider = ChangeNotifierProvider<ClipboardController>(
  (ref) {
    final controller = ClipboardController()..start();
    ref.onDispose(controller.dispose);
    return controller;
  },
);

final whatsAppVaultServiceProvider =
    Provider<WhatsAppVaultService>((ref) => WhatsAppVaultService());

final vaultControllerProvider = ChangeNotifierProvider<VaultController>(
  (ref) => VaultController(ref.watch(whatsAppVaultServiceProvider)),
);

final browserControllerProvider = ChangeNotifierProvider<BrowserController>(
  (ref) => BrowserController(),
);

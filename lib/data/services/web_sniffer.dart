import 'dart:convert';

import '../models/download_task.dart';

/// JavaScript injected into the in-app WebView. It hooks ``fetch``, XHR,
/// ``<video>/<audio>`` elements, MutationObserver and resource timing so the
/// app can offer a one-tap download for sniffed media URLs.
class WebSniffer {
  WebSniffer._();

  static const String channelName = 'VidKwaiiSniffer';

  static const String injectionScript = r'''
(function () {
  if (window.__vidkwaiiInstalled) return;
  window.__vidkwaiiInstalled = true;
  var seen = {};
  var mediaExt = /\.(mp4|m3u8|m4a|mp3|webm|mov|mkv|ts|aac|ogg|opus|flac|wav)(\?|#|$)/i;
  function report(url, type) {
    try {
      if (!url || seen[url] || !/^https?:/i.test(url)) return;
      seen[url] = true;
      window.VidKwaiiSniffer.postMessage(JSON.stringify({ url: url, type: type || 'media' }));
    } catch (e) {}
  }
  function hookMedia(el) {
    try {
      el.addEventListener('loadedmetadata', function () {
        if (el.currentSrc) report(el.currentSrc, 'media');
      });
      var origLoad = el.load;
      el.load = function () {
        if (this.currentSrc) report(this.currentSrc, 'media');
        return origLoad.apply(this, arguments);
      };
    } catch (e) {}
  }
  document.querySelectorAll('video,audio').forEach(hookMedia);
  new MutationObserver(function (mutations) {
    mutations.forEach(function (m) {
      m.addedNodes.forEach(function (n) {
        if (!n || n.nodeType !== 1) return;
        if (n.matches && n.matches('video,audio')) hookMedia(n);
        if (n.querySelectorAll) n.querySelectorAll('video,audio').forEach(hookMedia);
      });
    });
  }).observe(document.documentElement, { childList: true, subtree: true });
  var origFetch = window.fetch;
  window.fetch = function () {
    try {
      var url = typeof arguments[0] === 'string' ? arguments[0] : (arguments[0] && arguments[0].url);
      if (url && mediaExt.test(url)) report(url, 'media');
    } catch (e) {}
    return origFetch.apply(this, arguments);
  };
  var origOpen = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function (method, url) {
    try { if (url && mediaExt.test(url)) report(url, 'media'); } catch (e) {}
    return origOpen.apply(this, arguments);
  };
  if (window.PerformanceObserver) {
    try {
      new PerformanceObserver(function (list) {
        list.getEntries().forEach(function (entry) {
          if (mediaExt.test(entry.name)) report(entry.name, 'media');
        });
      }).observe({ entryTypes: ['resource'] });
    } catch (e) {}
  }
})();
''';

  static List<SniffedMedia> parse(String payload) {
    final items = <SniffedMedia>[];
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        items.add(SniffedMedia.fromJson(Map<String, dynamic>.from(decoded)));
      } else if (decoded is List) {
        for (final entry in decoded) {
          if (entry is Map) {
            items.add(SniffedMedia.fromJson(Map<String, dynamic>.from(entry)));
          }
        }
      }
    } catch (_) {
      // Ignore malformed payloads.
    }
    return items;
  }
}

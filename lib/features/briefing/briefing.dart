import 'dart:convert';

import '../../core/remote/remote_data.dart';
import '../../core/utils/bangla.dart';

/// One news headline (title + link to the original source).
class Headline {
  const Headline({
    required this.title,
    required this.source,
    required this.url,
    this.published,
    this.topic = '',
  });

  final String title;
  final String source;
  final String url;
  final DateTime? published;

  /// কৃষি | মাছ | বাজার | আবহাওয়া
  final String topic;

  factory Headline.fromMap(Map<dynamic, dynamic> m) => Headline(
        title: (m['title'] ?? '').toString(),
        source: (m['source'] ?? '').toString(),
        url: (m['url'] ?? '').toString(),
        published: DateTime.tryParse((m['published'] ?? '').toString())?.toLocal(),
        topic: (m['topic'] ?? '').toString(),
      );
}

/// Headlines collected every few hours by a GitHub Action
/// (.github/workflows/briefing.yml) and downloaded by [RemoteData].
class Briefing {
  const Briefing({this.updated, this.items = const []});

  final DateTime? updated;
  final List<Headline> items;

  static const file = 'briefing.json';

  static Briefing parse(String text) {
    final j = jsonDecode(text) as Map<String, dynamic>;
    return Briefing(
      updated: DateTime.tryParse((j['updated'] ?? '').toString())?.toLocal(),
      items: [
        for (final i in (j['items'] as List<dynamic>? ?? const []))
          if (i is Map) Headline.fromMap(i),
      ].where((h) => h.title.isNotEmpty && h.url.startsWith('https://')).toList(),
    );
  }

  static bool isValid(String text) {
    try {
      parse(text);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Latest downloaded headlines (empty if never online).
  static Future<Briefing> load() async {
    try {
      return parse(await RemoteData.textOrAsset(file));
    } catch (_) {
      return const Briefing();
    }
  }
}

/// "৩ ঘণ্টা আগে" style time.
String bnAgo(DateTime t, {DateTime? now}) {
  final d = (now ?? DateTime.now()).difference(t);
  if (d.inMinutes < 60) return '${Bn.digits(d.inMinutes.clamp(1, 59))} মিনিট আগে';
  if (d.inHours < 24) return '${Bn.digits(d.inHours)} ঘণ্টা আগে';
  if (d.inDays < 7) return '${Bn.digits(d.inDays)} দিন আগে';
  return Bn.date(t);
}

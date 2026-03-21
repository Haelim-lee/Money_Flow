import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stock.dart';

class NaverNewsService {
  static const _rssFeeds = [
    'https://www.mk.co.kr/rss/40300001/',
    'https://www.sedaily.com/RSS/rss_economy.xml',
  ];

  static const _rss2jsonBase = 'https://api.rss2json.com/v1/api.json';

  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  static String _relativeTime(String pubDate) {
    try {
      final dt = DateTime.parse(pubDate.trim());
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
      if (diff.inHours < 24) return '${diff.inHours}시간 전';
      return '${diff.inDays}일 전';
    } catch (_) {
      return '';
    }
  }

  static String _extractSource(String link) {
    try {
      final host = Uri.parse(link).host.replaceFirst('www.', '');
      const map = {
        'hankyung.com': '한국경제',
        'mk.co.kr': '매일경제',
        'edaily.co.kr': '이데일리',
        'etnews.com': '전자신문',
        'mt.co.kr': '머니투데이',
        'sedaily.com': '서울경제',
        'yna.co.kr': '연합뉴스',
        'chosun.com': '조선일보',
        'joongang.co.kr': '중앙일보',
        'donga.com': '동아일보',
      };
      return map[host] ?? host;
    } catch (_) {
      return '뉴스';
    }
  }

  static Future<List<NewsItem>> fetchStockNews({int display = 30}) async {
    final allItems = <NewsItem>[];

    for (final rss in _rssFeeds) {
      try {
        final url = '$_rss2jsonBase?rss_url=${Uri.encodeComponent(rss)}';
        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) continue;

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] != 'ok') continue;

        final items = data['items'] as List<dynamic>;
        for (final item in items) {
          final map = item as Map<String, dynamic>;
          allItems.add(NewsItem(
            title: _stripHtml(map['title'] as String? ?? ''),
            source: _extractSource(map['link'] as String? ?? ''),
            time: _relativeTime(map['pubDate'] as String? ?? ''),
            summary: _stripHtml(map['description'] as String? ?? ''),
          ));
        }
      } catch (_) {
        continue;
      }
    }

    if (allItems.isEmpty) throw Exception('뉴스를 불러오지 못했습니다');

    final seen = <String>{};
    return allItems.where((n) => seen.add(n.title)).take(display).toList();
  }
}

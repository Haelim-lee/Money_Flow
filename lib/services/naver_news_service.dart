import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stock.dart';

class NaverNewsService {
  static const _clientId = 'Y07FmNAOsd3ZuGhQ65WJ';
  static const _clientSecret = 'dVI4L72W6I';
  static const _baseUrl = 'https://openapi.naver.com/v1/search/news.json';

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
      final dt = DateTime.parse(
        pubDate.replaceFirst(RegExp(r' \+\d{4}$'), '').trim(),
      );
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
      if (diff.inHours < 24) return '${diff.inHours}시간 전';
      return '${diff.inDays}일 전';
    } catch (_) {
      return pubDate;
    }
  }

  static String _extractSource(String originalLink) {
    try {
      final uri = Uri.parse(originalLink);
      final host = uri.host.replaceFirst('www.', '');
      const map = {
        'hankyung.com': '한국경제',
        'mk.co.kr': '매일경제',
        'edaily.co.kr': '이데일리',
        'etnews.com': '전자신문',
        'mt.co.kr': '머니투데이',
        'sedaily.com': '서울경제',
        'inews24.com': '아이뉴스24',
        'newspim.com': '뉴스핌',
        'yna.co.kr': '연합뉴스',
        'news.naver.com': '네이버뉴스',
        'chosun.com': '조선일보',
        'joongang.co.kr': '중앙일보',
        'donga.com': '동아일보',
        'hani.co.kr': '한겨레',
      };
      return map[host] ?? host;
    } catch (_) {
      return '뉴스';
    }
  }

  static Future<List<NewsItem>> fetchStockNews({
    String query = '주식 증시',
    int display = 20,
  }) async {
    // Vercel serverless function proxy (avoids browser CORS restriction)
    const proxyBase = 'https://money-flow-haelim-lees-projects.vercel.app/api/news';
    final proxyUrl = '$proxyBase?query=${Uri.encodeComponent(query)}&display=$display';
    final response = await http.get(Uri.parse(proxyUrl));

    if (response.statusCode != 200) {
      throw Exception('뉴스를 불러오지 못했습니다 (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;

    return items.map((item) {
      final map = item as Map<String, dynamic>;
      return NewsItem(
        title: _stripHtml(map['title'] as String? ?? ''),
        source: _extractSource(map['originallink'] as String? ?? ''),
        time: _relativeTime(map['pubDate'] as String? ?? ''),
        summary: _stripHtml(map['description'] as String? ?? ''),
      );
    }).toList();
  }
}

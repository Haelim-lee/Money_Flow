import 'dart:convert';
import 'package:http/http.dart' as http;

class KisService {
  // Vercel 프록시 URL (CORS 우회)
  static const _proxy = 'https://mflow-proxy.vercel.app';

  // ── 현재가 조회 ────────────────────────────────────────────
  /// 반환: {price, change, changePercent, volume, isUp} or null
  static Future<Map<String, dynamic>?> getStockPrice(String symbol) async {
    try {
      final res = await http.get(
        Uri.parse('$_proxy/api/stock-price?symbol=$symbol'),
      );
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        return {
          'price': (d['price'] as num).toDouble(),
          'change': (d['change'] as num).toDouble(),
          'changePercent': (d['changePercent'] as num).toDouble(),
          'volume': (d['volume'] as num).toDouble(),
          'isUp': d['isUp'] as bool,
        };
      }
    } catch (_) {}
    return null;
  }

  // ── KOSPI / KOSDAQ 지수 조회 ───────────────────────────────
  /// index: '0001'=KOSPI, '1001'=KOSDAQ
  static Future<Map<String, dynamic>?> getMarketIndex(String index) async {
    try {
      final res = await http.get(
        Uri.parse('$_proxy/api/market-index?index=$index'),
      );
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        return {
          'value': (d['value'] as num).toDouble(),
          'change': (d['change'] as num).toDouble(),
          'changePercent': (d['changePercent'] as num).toDouble(),
          'isUp': d['isUp'] as bool,
        };
      }
    } catch (_) {}
    return null;
  }

  // ── 일봉 차트 데이터 ───────────────────────────────────────
  /// 최근 30거래일 종가 리스트 반환
  static Future<List<double>> getChartData(String symbol) async {
    try {
      final res = await http.get(
        Uri.parse('$_proxy/api/chart-data?symbol=$symbol'),
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body)['data'] as List? ?? [];
        return list.map((e) => (e as num).toDouble()).toList();
      }
    } catch (_) {}
    return [];
  }
}

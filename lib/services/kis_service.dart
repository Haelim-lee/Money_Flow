import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/kis_keys.dart';

class KisService {
  // 모의투자 base URL
  static const _base = 'https://openapivts.koreainvestment.com:29443';

  static String? _accessToken;
  static DateTime? _tokenExpiry;

  // ── 토큰 발급 ──────────────────────────────────────────────
  static Future<String?> _getToken() async {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken;
    }
    try {
      final res = await http.post(
        Uri.parse('$_base/oauth2/tokenP'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'grant_type': 'client_credentials',
          'appkey': KisKeys.appKey,
          'appsecret': KisKeys.appSecret,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _accessToken = data['access_token'];
        // 토큰 유효기간 1일 (실제 만료 10분 전 갱신)
        _tokenExpiry = DateTime.now().add(const Duration(hours: 23));
        return _accessToken;
      }
    } catch (_) {}
    return null;
  }

  static Map<String, String> _headers(String token, String trId) => {
        'Content-Type': 'application/json',
        'authorization': 'Bearer $token',
        'appkey': KisKeys.appKey,
        'appsecret': KisKeys.appSecret,
        'tr_id': trId,
        'custtype': 'P',
      };

  // ── 현재가 조회 ────────────────────────────────────────────
  /// 반환: {price, change, changePercent, volume} or null
  static Future<Map<String, dynamic>?> getStockPrice(String symbol) async {
    final token = await _getToken();
    if (token == null) return null;
    try {
      final res = await http.get(
        Uri.parse(
            '$_base/uapi/domestic-stock/v1/quotations/inquire-price'
            '?fid_cond_mrkt_div_code=J&fid_input_iscd=$symbol'),
        headers: _headers(token, 'FHKST01010100'),
      );
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body)['output'];
        return {
          'price': double.tryParse(d['stck_prpr'] ?? '0') ?? 0,
          'change': double.tryParse(d['prdy_vrss'] ?? '0') ?? 0,
          'changePercent': double.tryParse(d['prdy_ctrt'] ?? '0') ?? 0,
          'volume': double.tryParse(d['acml_vol'] ?? '0') ?? 0,
          'isUp': d['prdy_vrss_sign'] == '2', // 2=상승, 5=하락
        };
      }
    } catch (_) {}
    return null;
  }

  // ── KOSPI / KOSDAQ 지수 조회 ───────────────────────────────
  /// index: '0001'=KOSPI, '1001'=KOSDAQ
  static Future<Map<String, dynamic>?> getMarketIndex(String index) async {
    final token = await _getToken();
    if (token == null) return null;
    try {
      final res = await http.get(
        Uri.parse(
            '$_base/uapi/domestic-stock/v1/quotations/inquire-index-price'
            '?fid_cond_mrkt_div_code=U&fid_input_iscd=$index'),
        headers: _headers(token, 'FHPUP02100000'),
      );
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body)['output'];
        return {
          'value': double.tryParse(d['bstp_nmix_prpr'] ?? '0') ?? 0,
          'change': double.tryParse(d['bstp_nmix_prdy_vrss'] ?? '0') ?? 0,
          'changePercent': double.tryParse(d['bstp_nmix_prdy_ctrt'] ?? '0') ?? 0,
          'isUp': d['prdy_vrss_sign'] == '2',
        };
      }
    } catch (_) {}
    return null;
  }

  // ── 일봉 차트 데이터 ───────────────────────────────────────
  /// 최근 30거래일 종가 리스트 반환
  static Future<List<double>> getChartData(String symbol) async {
    final token = await _getToken();
    if (token == null) return [];
    final today = DateTime.now();
    final from = today.subtract(const Duration(days: 45));
    String fmt(DateTime d) =>
        '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
    try {
      final res = await http.get(
        Uri.parse(
            '$_base/uapi/domestic-stock/v1/quotations/inquire-daily-price'
            '?fid_cond_mrkt_div_code=J'
            '&fid_input_iscd=$symbol'
            '&fid_period_div_code=D'
            '&fid_org_adj_prc=0'
            '&fid_input_date_1=${fmt(from)}'
            '&fid_input_date_2=${fmt(today)}'),
        headers: _headers(token, 'FHKST01010400'),
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body)['output2'] as List? ?? [];
        return list
            .map((e) => double.tryParse(e['stck_clpr'] ?? '0') ?? 0.0)
            .where((v) => v > 0)
            .toList()
            .reversed
            .toList();
      }
    } catch (_) {}
    return [];
  }
}

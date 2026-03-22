import 'package:http/http.dart' as http;
import '../data/mock_data.dart';

class NtfyService {
  static const _topic = 'mflow-haerim16';
  static const _baseUrl = 'https://ntfy.sh';

  static Future<bool> send({
    required String title,
    required String body,
    String priority = 'default', // min, low, default, high, urgent
    String? tags,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$_topic'),
        headers: {
          'Title': title,
          'Priority': priority,
          if (tags != null) 'Tags': tags,
          'Content-Type': 'text/plain; charset=utf-8',
        },
        body: body,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> sendTest() {
    return send(
      title: '🔔 MFlow 알림 테스트',
      body: '알림이 정상적으로 작동합니다! 급등/급락 감지 알림이 이렇게 도착해요.',
      priority: 'default',
      tags: 'white_check_mark',
    );
  }

  /// 관심 종목 중 급등/급락 종목 감지 후 알림 전송
  static Future<List<String>> checkAndAlert({double threshold = 3.0}) async {
    final alerts = <String>[];
    for (final stock in mockStocks) {
      final pct = stock.changePercent.abs();
      if (pct >= threshold) {
        final isUp = stock.changePercent > 0;
        final emoji = isUp ? '🚀' : '📉';
        final dir = isUp ? '급등' : '급락';
        final sign = isUp ? '+' : '';
        final title = '$emoji ${stock.name} $dir';
        final body =
            '${stock.name}(${stock.symbol})이 $sign${stock.changePercent.toStringAsFixed(2)}% $dir 중입니다.\n'
            '현재가: ${stock.price.toStringAsFixed(0)}원';
        final ok = await send(
          title: title,
          body: body,
          priority: isUp ? 'high' : 'urgent',
          tags: isUp ? 'chart_with_upwards_trend' : 'chart_with_downwards_trend',
        );
        if (ok) alerts.add(stock.name);
      }
    }
    return alerts;
  }
}

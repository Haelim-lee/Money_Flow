import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/mock_data.dart';

class DiscordNotificationService {
  static const _webhookUrl =
      'https://discord.com/api/webhooks/1485288034961326213/rEDkj2cWpCTKAK53rmTe5woakjplqQXC8ZyU1mGO7M2IjOgHi1I4r8P65jn5cfgj9esy';

  static Future<bool> _send(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse(_webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> sendTest() {
    return _send({
      'embeds': [
        {
          'title': '🔔 MFlow 알림 테스트',
          'description': '알림이 정상적으로 작동합니다!\n급등/급락 감지 알림이 이렇게 도착해요.',
          'color': 0x1A1A2E,
          'footer': {'text': 'MFlow v1.2.1'},
        }
      ]
    });
  }

  /// 관심 종목 급등/급락 감지 (threshold: %)
  static Future<List<String>> checkAndAlert({double threshold = 3.0}) async {
    final alerted = <String>[];
    for (final stock in mockStocks) {
      final pct = stock.changePercent.abs();
      if (pct >= threshold) {
        final isUp = stock.changePercent > 0;
        final color = isUp ? 0xE53935 : 0x1E88E5;
        final emoji = isUp ? '🚀' : '📉';
        final dir = isUp ? '급등' : '급락';
        final sign = isUp ? '+' : '';

        final ok = await _send({
          'embeds': [
            {
              'title': '$emoji ${stock.name} $dir 감지',
              'description':
                  '**${stock.name}** (${stock.symbol})\n'
                  '등락률: **$sign${stock.changePercent.toStringAsFixed(2)}%**\n'
                  '현재가: ${stock.price.toStringAsFixed(0)}원',
              'color': color,
              'footer': {'text': 'MFlow 자동 감지 • v1.2.1'},
            }
          ]
        });
        if (ok) alerted.add(stock.name);
      }
    }
    return alerted;
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/stock.dart';
import '../services/naver_news_service.dart';
import '../data/mock_data.dart';

class ChartScreen extends StatefulWidget {
  final Stock stock;

  const ChartScreen({super.key, required this.stock});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  int _selectedPeriod = 0;
  final List<String> _periods = ['1일', '1주', '1개월', '3개월', '1년'];

  List<NewsItem> _relatedNews = [];
  bool _newsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRelatedNews();
  }

  Future<void> _loadRelatedNews() async {
    try {
      final all = await NaverNewsService.fetchStockNews(display: 30);
      final name = widget.stock.name;
      final filtered = all.where((n) =>
          n.title.contains(name) || n.summary.contains(name)).toList();
      setState(() {
        _relatedNews = filtered.isNotEmpty ? filtered : all.take(3).toList();
        _newsLoading = false;
      });
    } catch (_) {
      final name = widget.stock.name;
      final filtered = mockNews.where((n) =>
          n.title.contains(name) || n.summary.contains(name)).toList();
      setState(() {
        _relatedNews = filtered.isNotEmpty ? filtered : mockNews.take(3).toList();
        _newsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stock = widget.stock;
    final formatter = NumberFormat('#,###');
    final color = stock.isUp ? const Color(0xFFE53935) : const Color(0xFF1E88E5);
    final sign = stock.isUp ? '+' : '';

    final hasChart = stock.chartData.isNotEmpty;
    final spots = stock.chartData.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    final minY = hasChart
        ? stock.chartData.reduce((a, b) => a < b ? a : b) * 0.998
        : 0.0;
    final maxY = hasChart
        ? stock.chartData.reduce((a, b) => a > b ? a : b) * 1.002
        : 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(stock.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 가격 카드
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05), blurRadius: 10)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stock.symbol,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 13)),
                const SizedBox(height: 4),
                Text('${formatter.format(stock.price)}원',
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$sign${formatter.format(stock.change)}원 ($sign${stock.changePercent.toStringAsFixed(2)}%)',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 차트 카드
          if (!hasChart)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Center(
                child: Text('차트 데이터 없음',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
              ),
            ),
          if (hasChart)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05), blurRadius: 10)
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _periods.asMap().entries.map((e) {
                    final selected = e.key == _selectedPeriod;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedPeriod = e.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? color : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(e.value,
                            style: TextStyle(
                                color: selected ? Colors.white : Colors.grey,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.shade100,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minY: minY,
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: color,
                          barWidth: 2.5,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withOpacity(0.08),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (stock.price > 0) const SizedBox(height: 16),
          // 거래 정보
          if (stock.price > 0) Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05), blurRadius: 10)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('거래 정보',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                _infoRow('거래량',
                    '${formatter.format(stock.volume.toInt())}주'),
                _infoRow('거래대금',
                    '${formatter.format((stock.price * stock.volume / 1000000).toInt())}백만원'),
                _infoRow('전일 종가',
                    '${formatter.format((stock.price - stock.change).toInt())}원'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 기술적 분석
          if (stock.price > 0) _TechnicalAnalysis(stock: stock),
          const SizedBox(height: 16),
          // 외인/기관 동향
          if (stock.price > 0) _InstitutionalFlow(stock: stock),
          const SizedBox(height: 16),
          // 관련 뉴스
          const Text('관련 뉴스',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          if (_newsLoading)
            const Center(
                child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ))
          else
            ..._relatedNews.map((news) => _NewsItem(news: news)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}

class _TechnicalAnalysis extends StatelessWidget {
  final Stock stock;
  const _TechnicalAnalysis({required this.stock});

  // Returns sell date recommendations
  Map<String, dynamic> _sellDates(double rsi, String macd) {
    final now = DateTime.now();
    String fmt(DateTime d) {
      final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      return '${d.month}/${d.day}(${weekdays[d.weekday - 1]})';
    }

    // Skip weekends
    DateTime addWeekdays(DateTime base, int days) {
      var d = base;
      var added = 0;
      while (added < days) {
        d = d.add(const Duration(days: 1));
        if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) {
          added++;
        }
      }
      return d;
    }

    if (rsi < 35 && macd == '골든크로스') {
      final shortSell = addWeekdays(now, 1);
      final longSell = addWeekdays(now, 10);
      return {
        'short': '${fmt(shortSell)} ~ ${fmt(addWeekdays(now, 2))} (내일~모레)',
        'shortReason': '과매도 반등 구간 — 단기 반등 목표가 도달 시 분할 매도',
        'long': '${fmt(longSell)} ~ ${fmt(addWeekdays(now, 15))} (2~3주 후)',
        'longReason': '골든크로스 추세 지속 시 추가 상승 기대 — 고점 확인 후 매도',
      };
    }
    if (rsi > 65 && macd == '데드크로스') {
      return {
        'short': '오늘 장 마감 전 (15:00 이전)',
        'shortReason': '과매수 + 데드크로스 — 지금이 고점에 가까울 가능성, 빠른 매도 권장',
        'long': '보유 자제 — 추가 하락 시 손절 고려',
        'longReason': '하락 추세 진입 가능성 높음, 장기 보유 시 손실 확대 위험',
      };
    }
    if (rsi < 40) {
      final shortSell = addWeekdays(now, 2);
      final longSell = addWeekdays(now, 15);
      return {
        'short': '${fmt(shortSell)} ~ ${fmt(addWeekdays(now, 4))} (3~5일 후)',
        'shortReason': '저가 매수 후 단기 반등 시 매도 — 목표 수익률 도달 기준',
        'long': '${fmt(longSell)} ~ ${fmt(addWeekdays(now, 20))} (3~4주 후)',
        'longReason': '추세 전환 확인 후 보유 — RSI 60 도달 시 분할 매도',
      };
    }
    if (rsi > 60) {
      final shortSell = addWeekdays(now, 1);
      return {
        'short': '${fmt(shortSell)} (내일 오전 중)',
        'shortReason': '과매수 근접 — 추가 상승 시 차익 실현 타이밍',
        'long': '${fmt(addWeekdays(now, 5))} ~ ${fmt(addWeekdays(now, 8))} (1~2주 내)',
        'longReason': 'RSI 70 이상 진입 시 과매수 확정 — 단계적 매도 권장',
      };
    }
    if (macd == '골든크로스') {
      final longSell = addWeekdays(now, 10);
      return {
        'short': '${fmt(addWeekdays(now, 2))} ~ ${fmt(addWeekdays(now, 3))} (이번 주 내)',
        'shortReason': '상승 모멘텀 초기 — 단기 목표가 도달 시 일부 매도',
        'long': '${fmt(longSell)} ~ ${fmt(addWeekdays(now, 20))} (2~4주 후)',
        'longReason': '골든크로스 추세 유지 구간 — RSI 과매수 진입 전후 분할 매도',
      };
    }
    if (macd == '데드크로스') {
      return {
        'short': '오늘 ~ ${fmt(addWeekdays(now, 1))} (가능한 빨리)',
        'shortReason': '하락 압력 지속 — 추가 손실 방지를 위해 조기 매도 고려',
        'long': '추세 전환 신호 확인 전 보유 자제',
        'longReason': '데드크로스 이후 추세 반전까지 시간 필요, 반등 시 매도 기회',
      };
    }
    final mid = addWeekdays(now, 5);
    return {
      'short': '${fmt(addWeekdays(now, 3))} ~ ${fmt(mid)} (다음 주)',
      'shortReason': '뚜렷한 신호 없음 — 목표 수익률 설정 후 기계적 매도 권장',
      'long': '${fmt(addWeekdays(now, 15))} ~ ${fmt(addWeekdays(now, 25))} (3~5주 후)',
      'longReason': '지표 변화 모니터링 — 추세 형성 확인 후 재판단',
    };
  }

  // RSI calculation from chartData (simplified)
  double _calcRsi() {
    final data = stock.chartData;
    if (data.length < 2) return 50;
    double gains = 0, losses = 0;
    for (int i = 1; i < data.length; i++) {
      final diff = data[i] - data[i - 1];
      if (diff > 0) gains += diff;
      else losses += diff.abs();
    }
    if (losses == 0) return 100;
    final rs = gains / losses;
    return 100 - (100 / (1 + rs));
  }

  // MACD signal: compare short vs long moving average
  String _macdSignal() {
    final data = stock.chartData;
    if (data.length < 4) return '중립';
    final shortMA = data.sublist(data.length - 2).reduce((a, b) => a + b) / 2;
    final longMA = data.reduce((a, b) => a + b) / data.length;
    if (shortMA > longMA * 1.002) return '골든크로스';
    if (shortMA < longMA * 0.998) return '데드크로스';
    return '중립';
  }

  // Bollinger Band position
  String _bollingerPosition() {
    final data = stock.chartData;
    if (data.isEmpty) return '중간';
    final avg = data.reduce((a, b) => a + b) / data.length;
    final current = data.last;
    if (current > avg * 1.015) return '상단 (과매수)';
    if (current < avg * 0.985) return '하단 (과매도)';
    return '중간';
  }

  String _overallSignal(double rsi, String macd) {
    int score = 0;
    if (rsi < 35) score += 2;
    else if (rsi < 50) score += 1;
    else if (rsi > 65) score -= 2;
    else if (rsi > 50) score -= 1;
    if (macd == '골든크로스') score += 2;
    if (macd == '데드크로스') score -= 2;
    if (stock.isUp) score += 1;
    if (score >= 3) return '강력 매수';
    if (score >= 1) return '매수';
    if (score <= -3) return '강력 매도';
    if (score <= -1) return '매도';
    return '중립 관망';
  }

  String _timePrediction(double rsi, String macd) {
    if (rsi < 35 && macd == '골든크로스') return '단기 반등 가능 — 오늘 중 상승 시도 예상';
    if (rsi > 65 && macd == '데드크로스') return '단기 고점 가능 — 오후 조정 주의';
    if (rsi < 40) return '과매도 구간 — 수시간 내 반등 시도 가능';
    if (rsi > 60) return '과매수 구간 — 추가 상승 시 차익 실현 압력';
    if (macd == '골든크로스') return '상승 모멘텀 형성 — 내일 장 초반 강세 가능';
    if (macd == '데드크로스') return '하락 압력 지속 — 추가 조정 가능성';
    return '뚜렷한 방향성 없음 — 관망 권장';
  }

  // Returns mock time zone predictions based on indicators
  Map<String, dynamic> _timeZones(double rsi, String macd) {
    // Determine pattern
    if (rsi < 35 && macd == '골든크로스') {
      return {
        'rise': ['09:20 ~ 10:00', '13:00 ~ 14:00'],
        'fall': ['10:00 ~ 10:30'],
        'peak': '13:30 ~ 14:00',
        'note': '장 초반 강세 후 잠시 눌림, 오후 재상승 패턴',
        'reason': 'RSI ${rsi.toStringAsFixed(0)} → 과매도 상태라 저가 매수세 유입 가능성이 높고, MACD 골든크로스로 단기 상승 모멘텀이 형성됨. 이 조합에서 장 초반 급등 후 차익 실현 눌림, 오후 재매수 패턴이 자주 관찰됨.',
      };
    }
    if (rsi > 65 && macd == '데드크로스') {
      return {
        'rise': ['09:00 ~ 09:20'],
        'fall': ['09:30 ~ 11:00', '14:00 ~ 15:20'],
        'peak': '09:10 ~ 09:20 (이미 고점 가능성)',
        'note': '장 초반 매도 압력 강함, 오후 추가 하락 주의',
        'reason': 'RSI ${rsi.toStringAsFixed(0)} → 과매수 구간으로 차익 실현 압력이 크고, MACD 데드크로스로 단기 하락 모멘텀 진입. 이 조합은 장 초반 소폭 반등 후 매도세가 몰리는 패턴이 많음.',
      };
    }
    if (rsi < 40) {
      return {
        'rise': ['10:30 ~ 11:30', '14:30 ~ 15:20'],
        'fall': ['09:00 ~ 10:00'],
        'peak': '15:00 ~ 15:20',
        'note': '저가 매수세 오전 후반~오후 유입 가능성',
        'reason': 'RSI ${rsi.toStringAsFixed(0)} → 과매도 근접 구간. 장 초반 매도 잔여 물량 소화 후 오전 후반부터 저가 매수세 유입이 기대됨. 오후 장 마감 전 수급 집중 패턴.',
      };
    }
    if (rsi > 60) {
      return {
        'rise': ['09:00 ~ 09:30'],
        'fall': ['10:00 ~ 12:00'],
        'peak': '09:20 ~ 09:40',
        'note': '차익 실현 매물 오전 중반 집중 예상',
        'reason': 'RSI ${rsi.toStringAsFixed(0)} → 과매수 근접 구간. 장 초반 추가 상승 시도 후 오전 중반부터 차익 실현 매물이 쌓이는 흐름. 고점 이후 추가 매수는 위험.',
      };
    }
    if (macd == '골든크로스') {
      return {
        'rise': ['09:10 ~ 10:00', '14:00 ~ 15:00'],
        'fall': ['11:00 ~ 13:00'],
        'peak': '14:30 ~ 15:00',
        'note': '오전 급등 후 점심 눌림, 오후 2차 상승 패턴',
        'reason': 'MACD 골든크로스 → 단기 이동평균이 장기 이동평균을 상향 돌파해 상승 모멘텀 형성. RSI는 중립권이라 과매수 부담 없음. 전형적인 오전 강세 → 점심 눌림 → 오후 재상승 패턴.',
      };
    }
    if (macd == '데드크로스') {
      return {
        'rise': ['12:00 ~ 13:00'],
        'fall': ['09:30 ~ 11:30', '14:30 ~ 15:20'],
        'peak': '없음 (하락 추세)',
        'note': '점심 전후 기술적 반등 외 추세적 하락',
        'reason': 'MACD 데드크로스 → 단기 이동평균이 장기 이동평균 하향 돌파해 하락 압력 지속. 점심 전후 짧은 기술적 반등 가능하나 추세 전환 신호 없으면 매도 관점 유지 권장.',
      };
    }
    return {
      'rise': ['특정 시간대 없음'],
      'fall': ['특정 시간대 없음'],
      'peak': '불명확',
      'note': '뚜렷한 패턴 없음 — 관망 권장',
      'reason': 'RSI ${rsi.toStringAsFixed(0)}이 중립권이고 MACD도 뚜렷한 방향성이 없어 특정 시간대를 예측하기 어려운 상태.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final rsi = _calcRsi();
    final macd = _macdSignal();
    final bollinger = _bollingerPosition();
    final signal = _overallSignal(rsi, macd);
    final timePred = _timePrediction(rsi, macd);

    final signalColor = signal.contains('매수')
        ? const Color(0xFFE53935)
        : signal.contains('매도')
            ? const Color(0xFF1E88E5)
            : Colors.orange;

    final rsiColor = rsi < 35
        ? const Color(0xFF1E88E5)
        : rsi > 65
            ? const Color(0xFFE53935)
            : Colors.green;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('기술적 분석',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('MOCK',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 종합 신호
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: signalColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: signalColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(signal,
                    style: TextStyle(
                        color: signalColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                const SizedBox(height: 4),
                Text(timePred,
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // RSI
          _indicatorRow(
            'RSI',
            '${rsi.toStringAsFixed(1)}',
            rsi < 35 ? '과매도 — 반등 가능' : rsi > 65 ? '과매수 — 조정 주의' : '중립',
            rsiColor,
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rsi / 100,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(rsiColor.withOpacity(0.7)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),

          // MACD
          _indicatorRow(
            'MACD',
            macd,
            macd == '골든크로스'
                ? '단기 상승 모멘텀'
                : macd == '데드크로스'
                    ? '단기 하락 압력'
                    : '방향 미정',
            macd == '골든크로스'
                ? const Color(0xFFE53935)
                : macd == '데드크로스'
                    ? const Color(0xFF1E88E5)
                    : Colors.grey,
          ),
          const SizedBox(height: 12),

          // 볼린저밴드
          _indicatorRow(
            '볼린저밴드',
            bollinger,
            bollinger.contains('상단')
                ? '저항선 근접'
                : bollinger.contains('하단')
                    ? '지지선 근접, 반등 가능'
                    : '안정 구간',
            bollinger.contains('상단')
                ? const Color(0xFFE53935)
                : bollinger.contains('하단')
                    ? const Color(0xFF1E88E5)
                    : Colors.green,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // 시간대 예측
          Row(
            children: [
              const Text('시간대 예측',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('MOCK',
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.purple.shade400,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Builder(builder: (_) {
            final zones = _timeZones(rsi, macd);
            final riseZones = zones['rise'] as List<String>;
            final fallZones = zones['fall'] as List<String>;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _timeZoneRow('상승 예상', riseZones, const Color(0xFFE53935)),
                const SizedBox(height: 8),
                _timeZoneRow('하락 예상', fallZones, const Color(0xFF1E88E5)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('고점 예상  ',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12)),
                    Expanded(
                      child: Text(zones['peak'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(zones['note'] as String,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 11)),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 13, color: Colors.blue.shade600),
                          const SizedBox(width: 4),
                          Text('예측 근거',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Colors.blue.shade700)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(zones['reason'] as String,
                          style: TextStyle(
                              color: Colors.blue.shade900,
                              fontSize: 11,
                              height: 1.6)),
                    ],
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // 매도 권장 시점
          Row(
            children: [
              const Text('매도 권장 시점',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('MOCK',
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Builder(builder: (_) {
            final sell = _sellDates(rsi, macd);
            return Column(
              children: [
                _sellDateCard(
                  '단기',
                  sell['short'] as String,
                  sell['shortReason'] as String,
                  const Color(0xFFE53935),
                ),
                const SizedBox(height: 8),
                _sellDateCard(
                  '장기',
                  sell['long'] as String,
                  sell['longReason'] as String,
                  const Color(0xFF6D4C41),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _sellDateCard(String label, String date, String reason, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(date,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: color)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(reason,
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  height: 1.5)),
        ],
      ),
    );
  }

  Widget _timeZoneRow(String label, List<String> zones, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label  ',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: zones.map((z) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Text(z,
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _indicatorRow(String label, String value, String desc, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(desc,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ),
      ],
    );
  }
}

class _InstitutionalFlow extends StatelessWidget {
  final Stock stock;
  const _InstitutionalFlow({required this.stock});

  // Mock data based on stock symbol seed
  int _mockValue(String symbol, int base) {
    final seed = symbol.codeUnits.fold(0, (a, b) => a + b);
    final val = (seed * base) % 8000 - 4000;
    return val;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final foreignNet = _mockValue(stock.symbol, 137);
    final institutionNet = _mockValue(stock.symbol, 251);
    final retailNet = -(foreignNet + institutionNet);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('외인/기관 동향',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('MOCK',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('KIS API 연동 후 실시간 제공 예정',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
          const SizedBox(height: 14),
          _flowRow('외국인', foreignNet, formatter),
          const SizedBox(height: 10),
          _flowRow('기관', institutionNet, formatter),
          const SizedBox(height: 10),
          _flowRow('개인', retailNet, formatter),
        ],
      ),
    );
  }

  Widget _flowRow(String label, int net, NumberFormat formatter) {
    final isPositive = net >= 0;
    final color = isPositive ? const Color(0xFFE53935) : const Color(0xFF1E88E5);
    final sign = isPositive ? '+' : '';
    final dirLabel = isPositive ? '순매수' : '순매도';
    final barWidth = (net.abs() / 8000).clamp(0.0, 1.0);

    // Mock buy/sell breakdown
    final buyAmt = net.abs() + 1200;
    final sellAmt = isPositive ? 1200 : net.abs() + 1200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(dirLabel,
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
            const Spacer(),
            Text('$sign${formatter.format(net)}백만',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: barWidth,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.6)),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Text('매수 ${formatter.format(buyAmt)}백만',
                style: TextStyle(color: Colors.red.shade300, fontSize: 10)),
            const SizedBox(width: 10),
            Text('매도 ${formatter.format(sellAmt)}백만',
                style: TextStyle(color: Colors.blue.shade300, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

class _NewsItem extends StatelessWidget {
  final NewsItem news;
  const _NewsItem({required this.news});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(news.source,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E))),
              ),
              const SizedBox(width: 8),
              Text(news.time,
                  style:
                      TextStyle(color: Colors.grey.shade400, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 7),
          Text(news.title,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  height: 1.4)),
          if (news.summary.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(news.summary,
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

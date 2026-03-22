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

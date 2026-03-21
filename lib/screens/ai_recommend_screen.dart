import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/mock_data.dart';
import '../models/recommendation.dart';
import 'chart_screen.dart';
import '../data/mock_data.dart' show mockStocks;

class AiRecommendScreen extends StatefulWidget {
  const AiRecommendScreen({super.key});

  @override
  State<AiRecommendScreen> createState() => _AiRecommendScreenState();
}

class _AiRecommendScreenState extends State<AiRecommendScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('AI',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
            const SizedBox(width: 8),
            const Text('종목 추천',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6C63FF),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF6C63FF),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: '⚡ 단기 (2~4시간)'),
            Tab(text: '🌅 내일 유망주'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildAnalysisHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecommendList(mockShortTermRecs),
                _buildRecommendList(mockNextDayRecs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisHeader() {
    final now = DateTime.now();
    final timeStr = DateFormat('MM.dd HH:mm').format(now);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6C63FF).withOpacity(0.08),
              const Color(0xFF4ECDC4).withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFF6C63FF).withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome,
                color: Color(0xFF6C63FF), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI 분석 기준',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF6C63FF))),
                  const SizedBox(height: 2),
                  Text(
                    '거래량·이동평균·RSI·MACD·뉴스 모멘텀 종합 분석 · $timeStr 기준',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendList(List<StockRecommendation> recs) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recs.length,
      itemBuilder: (context, index) =>
          _RecommendCard(rec: recs[index], rank: index + 1),
    );
  }
}

class _RecommendCard extends StatelessWidget {
  final StockRecommendation rec;
  final int rank;

  const _RecommendCard({required this.rec, required this.rank});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final riskColor = switch (rec.riskLevel) {
      '낮음' => const Color(0xFF00C853),
      '높음' => const Color(0xFFE53935),
      _ => const Color(0xFFFF9800),
    };

    return GestureDetector(
      onTap: () {
        final stock = mockStocks.where((s) => s.symbol == rec.symbol).firstOrNull;
        if (stock != null) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => ChartScreen(stock: stock)));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          children: [
            // 상단: 종목 + 신뢰도
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 랭크 뱃지
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text('$rank',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rec.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            Text(rec.symbol,
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      // 리스크
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: riskColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('리스크 ${rec.riskLevel}',
                            style: TextStyle(
                                color: riskColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // 가격 + 예상 수익률
                  Row(
                    children: [
                      Expanded(
                        child: _PriceBox(
                          label: '현재가',
                          value: '${formatter.format(rec.currentPrice.toInt())}원',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PriceBox(
                          label: '목표가',
                          value: '${formatter.format(rec.targetPrice.toInt())}원',
                          highlight: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PriceBox(
                          label: '예상수익',
                          value: '+${rec.expectedReturnPercent.toStringAsFixed(2)}%',
                          highlight: true,
                          isReturn: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // 신뢰도 바
                  Row(
                    children: [
                      Text('AI 신뢰도',
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12)),
                      const Spacer(),
                      Text('${rec.confidenceScore}%',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF6C63FF))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: rec.confidenceScore / 100,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation(
                        rec.confidenceScore >= 75
                            ? const Color(0xFF6C63FF)
                            : rec.confidenceScore >= 60
                                ? const Color(0xFFFF9800)
                                : Colors.grey,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            // 하단: 분석 근거
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📊 분석 근거',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600)),
                  const SizedBox(height: 6),
                  ...rec.reasons.map((r) => Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ',
                                style: TextStyle(
                                    color: const Color(0xFF6C63FF),
                                    fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(r,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                      height: 1.4)),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceBox extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool isReturn;

  const _PriceBox({
    required this.label,
    required this.value,
    this.highlight = false,
    this.isReturn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: isReturn
            ? const Color(0xFFE53935).withOpacity(0.08)
            : highlight
                ? const Color(0xFF6C63FF).withOpacity(0.08)
                : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 10)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isReturn
                      ? const Color(0xFFE53935)
                      : highlight
                          ? const Color(0xFF6C63FF)
                          : Colors.black87),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

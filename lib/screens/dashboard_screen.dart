import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/mock_data.dart';
import '../models/recommendation.dart';
import '../models/stock.dart';
import '../services/discord_notification_service.dart';
import '../services/kis_service.dart';
import '../widgets/stock_card.dart';
import 'chart_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _alertSending = false;

  // 실시간 지수
  String _kospiVal = '2,654.23';
  String _kospiChg = '+1.23%';
  bool _kospiUp = true;
  String _kosdaqVal = '872.45';
  String _kosdaqChg = '-0.45%';
  bool _kosdaqUp = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMarketIndex();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMarketIndex() async {
    final fmt = NumberFormat('#,##0.00');
    final kospi = await KisService.getMarketIndex('0001');
    final kosdaq = await KisService.getMarketIndex('1001');
    if (!mounted) return;
    setState(() {
      if (kospi != null) {
        _kospiVal = fmt.format(kospi['value']);
        final sign = kospi['isUp'] ? '+' : '';
        _kospiChg = '$sign${(kospi['changePercent'] as double).toStringAsFixed(2)}%';
        _kospiUp = kospi['isUp'];
      }
      if (kosdaq != null) {
        _kosdaqVal = fmt.format(kosdaq['value']);
        final sign = kosdaq['isUp'] ? '+' : '';
        _kosdaqChg = '$sign${(kosdaq['changePercent'] as double).toStringAsFixed(2)}%';
        _kosdaqUp = kosdaq['isUp'];
      }
    });
  }

  void _showAlertSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AlertSheet(
        onTest: () async {
          Navigator.pop(context);
          setState(() => _alertSending = true);
          final ok = await DiscordNotificationService.sendTest();
          setState(() => _alertSending = false);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(ok ? '✅ 테스트 알림을 Discord로 전송했어요!' : '❌ 전송 실패 — 네트워크를 확인해주세요'),
              backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
            ));
          }
        },
        onScan: () async {
          Navigator.pop(context);
          setState(() => _alertSending = true);
          final alerted = await DiscordNotificationService.checkAndAlert(threshold: 2.0);
          setState(() => _alertSending = false);
          if (context.mounted) {
            final msg = alerted.isEmpty
                ? '감지된 급등/급락 종목이 없어요 (기준: ±2% 이상)'
                : '📨 ${alerted.length}개 종목 알림 전송: ${alerted.join(', ')}';
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(msg),
              backgroundColor: alerted.isEmpty ? Colors.grey.shade700 : Colors.green.shade700,
            ));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = DateFormat('MM.dd HH:mm').format(now);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1A1A2E),
            actions: [
              if (_alertSending)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                  ),
                )
              else
                Builder(builder: (ctx) => IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white70, size: 22),
                  onPressed: () => _showAlertSheet(ctx),
                  tooltip: '알림 설정',
                )),
              Padding(
                padding: const EdgeInsets.only(right: 16, top: 8),
                child: Text(
                  'v1.2.3',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('MFlow',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _indexBadge('KOSPI', _kospiVal, _kospiChg, _kospiUp),
                        const SizedBox(width: 8),
                        _indexBadge('KOSDAQ', _kosdaqVal, _kosdaqChg, _kosdaqUp),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(timeStr,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11)),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 2.5,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: '관심 종목'),
                Tab(text: 'AI 추천'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _WatchlistTab(),
            _AiTab(),
          ],
        ),
      ),
    );
  }

  Widget _indexBadge(String name, String value, String change, bool isUp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(name,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(width: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
          const SizedBox(width: 4),
          Text(change,
              style: TextStyle(
                  color: isUp
                      ? const Color(0xFFFF6B6B)
                      : const Color(0xFF74B9FF),
                  fontSize: 11)),
        ],
      ),
    );
  }
}

class _WatchlistTab extends StatefulWidget {
  @override
  State<_WatchlistTab> createState() => _WatchlistTabState();
}

class _WatchlistTabState extends State<_WatchlistTab> {
  late List<Stock> _stocks;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _stocks = List.from(mockStocks);
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    final updated = await Future.wait<Stock>(
      _stocks.map((s) async {
        final data = await KisService.getStockPrice(s.symbol);
        if (data == null) return s;
        return s.copyWith(
          price: data['price'],
          change: data['change'],
          changePercent: data['changePercent'],
          volume: data['volume'],
        );
      }),
    );
    if (!mounted) return;
    setState(() {
      _stocks = updated;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  children: _stocks
                      .map((s) => StockCard(
                            stock: s,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ChartScreen(stock: s)),
                            ),
                          ))
                      .toList(),
                ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _AiTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('⚡ 단기 추천', '수시간~1일'),
        const SizedBox(height: 10),
        ...mockShortTermRecs.map((r) => _AiRecCard(rec: r)),
        const SizedBox(height: 20),
        _sectionHeader('🌟 내일 유망주', '다음날 기준'),
        const SizedBox(height: 10),
        ...mockNextDayRecs.map((r) => _AiRecCard(rec: r)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Text(subtitle,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      ],
    );
  }
}

class _AiRecCard extends StatelessWidget {
  final StockRecommendation rec;
  const _AiRecCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final returnColor = rec.expectedReturnPercent >= 0
        ? const Color(0xFFE53935)
        : const Color(0xFF1E88E5);
    final riskColor = rec.riskLevel == '낮음'
        ? Colors.green
        : rec.riskLevel == '보통'
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rec.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(rec.symbol,
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '+${rec.expectedReturnPercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                        color: returnColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  Text('목표 ${formatter.format(rec.targetPrice)}원',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _badge('신뢰도 ${rec.confidenceScore}%', const Color(0xFF1A1A2E)),
              const SizedBox(width: 6),
              _badge('리스크 ${rec.riskLevel}', riskColor),
            ],
          ),
          const SizedBox(height: 10),
          ...rec.reasons.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    Icon(Icons.circle,
                        size: 5, color: Colors.grey.shade400),
                    const SizedBox(width: 6),
                    Text(r,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }
}

class _AlertSheet extends StatelessWidget {
  final VoidCallback onTest;
  final VoidCallback onScan;
  const _AlertSheet({required this.onTest, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.notifications, color: Color(0xFF1A1A2E), size: 20),
              const SizedBox(width: 8),
              const Text('Discord 알림',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('연결됨',
                    style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _alertButton(
            icon: Icons.send_outlined,
            label: '테스트 알림 전송',
            subtitle: 'Discord로 테스트 메시지 전송',
            color: const Color(0xFF1A1A2E),
            onTap: onTest,
          ),
          const SizedBox(height: 10),
          _alertButton(
            icon: Icons.search,
            label: '급등/급락 종목 스캔',
            subtitle: '관심 종목 중 ±2% 이상 변동 종목 알림',
            color: const Color(0xFFE53935),
            onTap: onScan,
          ),
        ],
      ),
    );
  }

  Widget _alertButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/mock_data.dart';
import '../models/stock.dart';
import '../services/naver_news_service.dart';
import '../services/news_analysis_service.dart';
import 'chart_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<NewsItem> _news = [];
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  static const int _pageSize = 10;
  int _displayCount = _pageSize;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchNews();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchNews() async {
    try {
      final news = await NaverNewsService.fetchStockNews(display: 30);
      setState(() {
        _news = news;
        _isInitialLoading = false;
      });
    } catch (e) {
      setState(() {
        _news = mockNews;
        _isInitialLoading = false;
        _error = '실시간 뉴스 로드 실패 — 샘플 데이터를 표시합니다';
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _displayCount >= _news.length) return;
    setState(() => _isLoadingMore = true);
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() {
      _displayCount = (_displayCount + _pageSize).clamp(0, _news.length);
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('오늘의 주식 뉴스',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isInitialLoading = true;
                _error = null;
                _displayCount = _pageSize;
              });
              _fetchNews();
            },
          ),
        ],
      ),
      body: _isInitialLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_error != null)
                  Container(
                    width: double.infinity,
                    color: Colors.orange.shade50,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Text(_error!,
                        style: TextStyle(
                            color: Colors.orange.shade700, fontSize: 12)),
                  ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _displayCount.clamp(0, _news.length) + 1,
                    itemBuilder: (context, index) {
                      final visible = _displayCount.clamp(0, _news.length);
                      if (index == visible) {
                        if (_isLoadingMore) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2)),
                          );
                        }
                        if (_displayCount >= _news.length) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text('모든 뉴스를 불러왔습니다',
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 13)),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }

                      final news = _news[index];
                      return _NewsCard(news: news);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _StockPredictionTile extends StatelessWidget {
  final StockPrediction prediction;
  const _StockPredictionTile({required this.prediction});

  void _navigateToStock(BuildContext context) {
    // Find stock in mockStocks or create a minimal one
    final existing = [...mockStocks, ...mockHotStocks]
        .where((s) => s.symbol == prediction.symbol)
        .firstOrNull;

    final stock = existing ??
        Stock(
          symbol: prediction.symbol,
          name: prediction.name,
          price: 0,
          change: 0,
          changePercent: 0,
          volume: 0,
          chartData: const [],
        );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChartScreen(stock: stock)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = prediction.isUp ? const Color(0xFFE53935) : const Color(0xFF1565C0);
    final icon = prediction.isUp ? Icons.trending_up : Icons.trending_down;
    final label = prediction.isUp ? '상승 예상' : '하락 예상';

    return GestureDetector(
      onTap: () => _navigateToStock(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(prediction.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(prediction.reason,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: color.withOpacity(0.5), size: 18),
          ],
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsItem news;
  const _NewsCard({required this.news});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            _showDetail(context, news.title, news.summary, news.link),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(news.source,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E))),
                  ),
                  const SizedBox(width: 8),
                  Text(news.time,
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 8),
              Text(news.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      height: 1.4)),
              const SizedBox(height: 6),
              Text(news.summary,
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(
      BuildContext context, String title, String summary, String link) {
    final analysis = NewsAnalysisService.analyze(title, summary);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.4)),
              const SizedBox(height: 16),
              Text(summary,
                  style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 15,
                      height: 1.6)),
              const SizedBox(height: 24),

              // AI Analysis Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E).withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF1A1A2E).withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.analytics_outlined,
                            size: 16, color: Color(0xFF1A1A2E)),
                        const SizedBox(width: 6),
                        const Text('뉴스 분석',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1A1A2E))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(analysis.summary,
                        style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                            height: 1.5)),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              if (link.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(link);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('원문 보기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A2E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

              if (analysis.predictions.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('관련 종목 예상',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 10),
                ...analysis.predictions.map((p) => _StockPredictionTile(prediction: p)),
              ] else ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.grey.shade400),
                      const SizedBox(width: 8),
                      Text('관련 종목을 찾지 못했습니다',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

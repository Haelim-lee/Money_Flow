import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/stock.dart';
import '../widgets/stock_card.dart';
import 'chart_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Stock> _results = [];
  bool _searched = false;

  void _search(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _searched = q.isNotEmpty;
      if (q.isEmpty) {
        _results = [];
      } else {
        _results = [...mockStocks, ...mockHotStocks]
            .where((s) =>
                s.name.toLowerCase().contains(q) ||
                s.symbol.contains(q))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('종목 검색',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _controller,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: '종목명 또는 종목코드 검색',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _controller.clear();
                          _search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _searched
                ? _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('검색 결과가 없습니다',
                                style: TextStyle(color: Colors.grey.shade400)),
                          ],
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: Column(
                          children: _results
                              .map((s) => StockCard(
                                    stock: s,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              ChartScreen(stock: s)),
                                    ),
                                  ))
                              .toList(),
                        ),
                      )
                : _buildPopularList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('인기 종목',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05), blurRadius: 10)
            ],
          ),
          child: Column(
            children: mockStocks
                .take(5)
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
      ],
    );
  }
}

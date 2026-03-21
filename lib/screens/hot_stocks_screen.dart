import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/mock_data.dart';
import '../models/stock.dart';
import 'chart_screen.dart';

class HotStocksScreen extends StatelessWidget {
  const HotStocksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('실시간 급등주',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text('LIVE',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('🔥 급등 TOP 5'),
          const SizedBox(height: 8),
          ...mockHotStocks.asMap().entries.map((e) =>
              _HotStockItem(rank: e.key + 1, stock: e.value, onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ChartScreen(stock: e.value)),
                );
              })),
          const SizedBox(height: 24),
          _buildSectionHeader('📊 거래량 상위'),
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
                  .sorted((a, b) => b.volume.compareTo(a.volume))
                  .take(5)
                  .map((s) => _VolumeItem(stock: s, onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ChartScreen(stock: s)),
                        );
                      }))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
  }
}

extension _ListSort<T> on List<T> {
  List<T> sorted(int Function(T, T) compare) => [...this]..sort(compare);
}

class _HotStockItem extends StatelessWidget {
  final int rank;
  final Stock stock;
  final VoidCallback onTap;

  const _HotStockItem(
      {required this.rank, required this.stock, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: rank <= 3
                    ? const Color(0xFFE53935)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text('$rank',
                    style: TextStyle(
                        color: rank <= 3 ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stock.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(stock.symbol,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${formatter.format(stock.price)}원',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+${stock.changePercent.toStringAsFixed(2)}%',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VolumeItem extends StatelessWidget {
  final Stock stock;
  final VoidCallback onTap;

  const _VolumeItem({required this.stock, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final color = stock.isUp ? const Color(0xFFE53935) : const Color(0xFF1E88E5);
    final sign = stock.isUp ? '+' : '';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stock.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('거래량 ${formatter.format(stock.volume)}',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${formatter.format(stock.price)}원',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text('$sign${stock.changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(color: color, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

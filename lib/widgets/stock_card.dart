import 'package:flutter/material.dart';
import '../models/stock.dart';
import 'package:intl/intl.dart';

class StockCard extends StatelessWidget {
  final Stock stock;
  final VoidCallback? onTap;

  const StockCard({super.key, required this.stock, this.onTap});

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
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            // 종목 아이콘
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  stock.name[0],
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 종목명
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stock.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(stock.symbol,
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            // 가격
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${formatter.format(stock.price)}원',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  '$sign${formatter.format(stock.change)} ($sign${stock.changePercent.toStringAsFixed(2)}%)',
                  style: TextStyle(color: color, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

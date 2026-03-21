class Stock {
  final String symbol;
  final String name;
  final double price;
  final double change;
  final double changePercent;
  final double volume;
  final List<double> chartData;

  const Stock({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.volume,
    this.chartData = const [],
  });

  bool get isUp => change >= 0;
}

class NewsItem {
  final String title;
  final String source;
  final String time;
  final String summary;

  const NewsItem({
    required this.title,
    required this.source,
    required this.time,
    required this.summary,
  });
}

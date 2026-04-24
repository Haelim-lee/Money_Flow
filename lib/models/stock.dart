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

  Stock copyWith({
    double? price,
    double? change,
    double? changePercent,
    double? volume,
    List<double>? chartData,
  }) {
    return Stock(
      symbol: symbol,
      name: name,
      price: price ?? this.price,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      volume: volume ?? this.volume,
      chartData: chartData ?? this.chartData,
    );
  }
}

class NewsItem {
  final String title;
  final String source;
  final String time;
  final String summary;
  final String link;

  const NewsItem({
    required this.title,
    required this.source,
    required this.time,
    required this.summary,
    this.link = '',
  });
}

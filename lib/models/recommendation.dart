enum RecommendPeriod { shortTerm, nextDay }

class StockRecommendation {
  final String symbol;
  final String name;
  final double currentPrice;
  final double targetPrice;
  final double expectedReturnPercent;
  final int confidenceScore; // 0~100
  final RecommendPeriod period;
  final List<String> reasons;
  final String riskLevel; // '낮음' | '보통' | '높음'

  const StockRecommendation({
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.targetPrice,
    required this.expectedReturnPercent,
    required this.confidenceScore,
    required this.period,
    required this.reasons,
    required this.riskLevel,
  });
}

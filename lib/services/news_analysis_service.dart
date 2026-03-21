class StockPrediction {
  final String symbol;
  final String name;
  final bool isUp;
  final String reason;

  const StockPrediction({
    required this.symbol,
    required this.name,
    required this.isUp,
    required this.reason,
  });
}

class NewsAnalysisResult {
  final String summary;
  final List<StockPrediction> predictions;

  const NewsAnalysisResult({
    required this.summary,
    required this.predictions,
  });
}

class NewsAnalysisService {
  static const _stockKeywords = <String, Map<String, String>>{
    '삼성전자': {'symbol': '005930', 'name': '삼성전자'},
    '삼성': {'symbol': '005930', 'name': '삼성전자'},
    'SK하이닉스': {'symbol': '000660', 'name': 'SK하이닉스'},
    '하이닉스': {'symbol': '000660', 'name': 'SK하이닉스'},
    'LG에너지솔루션': {'symbol': '373220', 'name': 'LG에너지솔루션'},
    '카카오': {'symbol': '035720', 'name': '카카오'},
    '네이버': {'symbol': '035420', 'name': 'NAVER'},
    'NAVER': {'symbol': '035420', 'name': 'NAVER'},
    '현대차': {'symbol': '005380', 'name': '현대자동차'},
    '현대자동차': {'symbol': '005380', 'name': '현대자동차'},
    '기아': {'symbol': '000270', 'name': '기아'},
    '셀트리온': {'symbol': '068270', 'name': '셀트리온'},
    '포스코': {'symbol': '005490', 'name': 'POSCO홀딩스'},
    'LG전자': {'symbol': '066570', 'name': 'LG전자'},
    'LG화학': {'symbol': '051910', 'name': 'LG화학'},
    '한화': {'symbol': '000880', 'name': '한화'},
    'KB금융': {'symbol': '105560', 'name': 'KB금융'},
    '신한': {'symbol': '055550', 'name': '신한지주'},
    '하나금융': {'symbol': '086790', 'name': '하나금융지주'},
    '우리금융': {'symbol': '316140', 'name': '우리금융지주'},
    '삼성바이오': {'symbol': '207940', 'name': '삼성바이오로직스'},
    'HMM': {'symbol': '011200', 'name': 'HMM'},
    '애플': {'symbol': 'AAPL', 'name': 'Apple'},
    '테슬라': {'symbol': 'TSLA', 'name': 'Tesla'},
    '엔비디아': {'symbol': 'NVDA', 'name': 'NVIDIA'},
  };

  static const _positiveKeywords = [
    '상승', '급등', '호실적', '매출 증가', '영업이익 증가', '영업이익 개선',
    '수주', '수주 계약', '흑자', '흑자전환', '호재', '강세', '목표가 상향',
    '신고가', '투자 확대', '신제품', '돌파', '기대감', '성장', '회복',
    '개선', '수익 증가', '실적 호조', '매수', '강력 매수', '어닝서프라이즈',
    '계약 체결', '협약', '파트너십', '수출 증가', '점유율 확대',
  ];

  static const _negativeKeywords = [
    '하락', '급락', '적자', '매출 감소', '영업이익 감소', '적자전환',
    '취소', '손실', '침체', '악재', '약세', '목표가 하향', '감원',
    '리콜', '사고', '제재', '규제', '과징금', '소송', '파업',
    '실적 부진', '매도', '불확실성', '우려', '부진', '위축',
    '수출 감소', '점유율 축소', '구조조정',
  ];

  static NewsAnalysisResult analyze(String title, String summary) {
    final text = '$title $summary';

    // Find matched stocks
    final matched = <String, Map<String, String>>{};
    for (final entry in _stockKeywords.entries) {
      if (text.contains(entry.key)) {
        final symbol = entry.value['symbol']!;
        matched.putIfAbsent(symbol, () => entry.value);
      }
    }

    // Count sentiment
    int positiveScore = 0;
    int negativeScore = 0;
    final matchedPositive = <String>[];
    final matchedNegative = <String>[];

    for (final kw in _positiveKeywords) {
      if (text.contains(kw)) {
        positiveScore++;
        matchedPositive.add(kw);
      }
    }
    for (final kw in _negativeKeywords) {
      if (text.contains(kw)) {
        negativeScore++;
        matchedNegative.add(kw);
      }
    }

    final isPositive = positiveScore >= negativeScore;

    // Build summary
    String summaryText;
    if (positiveScore == 0 && negativeScore == 0) {
      summaryText = '중립적인 뉴스입니다. 뚜렷한 호재/악재 신호가 없습니다.';
    } else if (isPositive) {
      final kws = matchedPositive.take(3).join(', ');
      summaryText = '긍정 신호 감지: $kws 등의 키워드가 포함되어 있습니다.';
    } else {
      final kws = matchedNegative.take(3).join(', ');
      summaryText = '부정 신호 감지: $kws 등의 키워드가 포함되어 있습니다.';
    }

    // Build predictions
    final predictions = matched.values.map((stock) {
      String reason;
      if (positiveScore == 0 && negativeScore == 0) {
        reason = '직접적인 영향 신호 없음';
      } else if (isPositive) {
        reason = matchedPositive.isNotEmpty
            ? '${matchedPositive.first} 관련 긍정 뉴스'
            : '긍정적 흐름';
      } else {
        reason = matchedNegative.isNotEmpty
            ? '${matchedNegative.first} 관련 부정 뉴스'
            : '부정적 흐름';
      }
      return StockPrediction(
        symbol: stock['symbol']!,
        name: stock['name']!,
        isUp: positiveScore >= negativeScore,
        reason: reason,
      );
    }).toList();

    return NewsAnalysisResult(
      summary: summaryText,
      predictions: predictions,
    );
  }
}

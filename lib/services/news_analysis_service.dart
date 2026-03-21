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

class _SectorRule {
  final List<String> triggers;
  final List<String> stocks;
  final bool isUp;
  final String reason;

  const _SectorRule({
    required this.triggers,
    required this.stocks,
    required this.isUp,
    required this.reason,
  });
}

class NewsAnalysisService {
  static const _companyKeywords = <String, Map<String, String>>{
    '삼성전자': {'symbol': '005930', 'name': '삼성전자'},
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
    'KB금융': {'symbol': '105560', 'name': 'KB금융'},
    '신한': {'symbol': '055550', 'name': '신한지주'},
    '하나금융': {'symbol': '086790', 'name': '하나금융지주'},
    '삼성바이오': {'symbol': '207940', 'name': '삼성바이오로직스'},
    'HMM': {'symbol': '011200', 'name': 'HMM'},
    '한화에어로스페이스': {'symbol': '012450', 'name': '한화에어로스페이스'},
    '한화에어로': {'symbol': '012450', 'name': '한화에어로스페이스'},
    '현대로템': {'symbol': '064350', 'name': '현대로템'},
    'LIG넥스원': {'symbol': '079550', 'name': 'LIG넥스원'},
    '한국항공우주': {'symbol': '047810', 'name': '한국항공우주(KAI)'},
    'KAI': {'symbol': '047810', 'name': '한국항공우주(KAI)'},
    '한화시스템': {'symbol': '272210', 'name': '한화시스템'},
    'HYBE': {'symbol': '352820', 'name': 'HYBE'},
    '하이브': {'symbol': '352820', 'name': 'HYBE'},
    'SM엔터': {'symbol': '041510', 'name': 'SM엔터테인먼트'},
    'JYP': {'symbol': '035900', 'name': 'JYP Ent.'},
    'YG엔터': {'symbol': '122870', 'name': 'YG엔터테인먼트'},
    'CJ ENM': {'symbol': '035760', 'name': 'CJ ENM'},
    '두산에너빌리티': {'symbol': '034020', 'name': '두산에너빌리티'},
    '한국전력': {'symbol': '015760', 'name': '한국전력'},
    '한전': {'symbol': '015760', 'name': '한국전력'},
    '삼성SDI': {'symbol': '006400', 'name': '삼성SDI'},
    '에코프로': {'symbol': '086520', 'name': '에코프로'},
    '애플': {'symbol': 'AAPL', 'name': 'Apple'},
    '테슬라': {'symbol': 'TSLA', 'name': 'Tesla'},
    '엔비디아': {'symbol': 'NVDA', 'name': 'NVIDIA'},
  };

  static const _sectorRules = <_SectorRule>[
    _SectorRule(
      triggers: ['전쟁', '분쟁', '전투', '교전', '침공', '군사', '무기', '방위', '방산',
                 '미사일', '드론', '포탄', '탄약', '국방', '안보', '군비', '폭격', '공습',
                 '전쟁 위기', '군사 충돌', '무장', '전력 증강'],
      stocks: ['012450', '064350', '079550', '047810', '272210'],
      isUp: true,
      reason: '전쟁/방위 이슈 → 방산주 수혜',
    ),
    _SectorRule(
      triggers: ['휴전', '평화협정', '종전', '비핵화', '군비 축소', '철군'],
      stocks: ['012450', '064350', '079550', '047810'],
      isUp: false,
      reason: '평화 무드 → 방산주 조정 가능',
    ),
    _SectorRule(
      triggers: ['아이돌', 'K팝', 'K-pop', 'Kpop', '앨범', '음반', '콘서트', '투어',
                 '빌보드', '그래미', '데뷔', '컴백', '팬덤', '음원', '스트리밍',
                 '걸그룹', '보이그룹', '뮤직비디오'],
      stocks: ['352820', '041510', '035900', '122870'],
      isUp: true,
      reason: 'K팝/엔터 흥행 → 엔터주 수혜',
    ),
    _SectorRule(
      triggers: ['드라마', 'OTT', '넷플릭스', 'Netflix', '디즈니플러스', '시청률',
                 '영화 흥행', '박스오피스', '예능', '방송'],
      stocks: ['035760', '352820', '041510'],
      isUp: true,
      reason: '콘텐츠 흥행 → 엔터/미디어주 수혜',
    ),
    _SectorRule(
      triggers: ['연예인', '스캔들', '논란', '구설', '팬 이탈', '불매'],
      stocks: ['352820', '041510', '035900', '122870'],
      isUp: false,
      reason: '연예인 논란 → 엔터주 리스크',
    ),
    _SectorRule(
      triggers: ['반도체', 'HBM', 'AI칩', 'GPU', '파운드리', '메모리', 'D램', 'DRAM',
                 '낸드', 'NAND', '반도체 수요', '반도체 부족', '반도체 호황'],
      stocks: ['005930', '000660'],
      isUp: true,
      reason: '반도체 수요 증가 → 반도체주 수혜',
    ),
    _SectorRule(
      triggers: ['반도체 규제', '반도체 제재', '수출 통제', '칩 규제', '반도체 수출 금지'],
      stocks: ['005930', '000660'],
      isUp: false,
      reason: '반도체 수출 규제 → 반도체주 타격',
    ),
    _SectorRule(
      triggers: ['전기차', 'EV', '배터리', '2차전지', '리튬', '양극재',
                 '전기차 수요', '배터리 수주'],
      stocks: ['373220', '006400', '051910', '086520'],
      isUp: true,
      reason: '전기차/배터리 성장 → 2차전지주 수혜',
    ),
    _SectorRule(
      triggers: ['금리 인상', '기준금리 인상', '긴축', '금리 올리'],
      stocks: ['105560', '055550', '086790'],
      isUp: true,
      reason: '금리 인상 → 금융주 수혜',
    ),
    _SectorRule(
      triggers: ['금리 인하', '기준금리 인하', '금리 내리', '피벗'],
      stocks: ['105560', '055550', '086790'],
      isUp: false,
      reason: '금리 인하 → 금융주 마진 축소',
    ),
    _SectorRule(
      triggers: ['원자력', '원전', '핵발전', 'SMR', '소형모듈원자로', '원전 건설'],
      stocks: ['034020', '015760'],
      isUp: true,
      reason: '원전 확대 → 원전주 수혜',
    ),
    _SectorRule(
      triggers: ['AI', '인공지능', '챗GPT', 'ChatGPT', '대형언어모델', 'LLM', '생성형 AI'],
      stocks: ['005930', '000660', '035420'],
      isUp: true,
      reason: 'AI 성장 → 반도체·플랫폼주 수혜',
    ),
    _SectorRule(
      triggers: ['해운', '컨테이너', '운임', '물류 대란', '선박 부족'],
      stocks: ['011200'],
      isUp: true,
      reason: '해운 운임 상승 → HMM 수혜',
    ),
    _SectorRule(
      triggers: ['관세', '무역전쟁', '통상 마찰', '수입 규제', '무역 분쟁'],
      stocks: ['005380', '000270', '005930'],
      isUp: false,
      reason: '무역 분쟁 → 수출 의존주 타격',
    ),
  ];

  static const _positiveKeywords = [
    '급등', '상승', '호실적', '흑자전환', '흑자', '수주', '계약 체결', '파트너십',
    '성장', '신고가', '목표가 상향', '어닝서프라이즈', '실적 호조', '수출 증가',
    '점유율 확대', '매출 증가', '영업이익 증가', '투자 유치', 'IPO',
    '회복', '개선', '돌파', '대규모 수주', '독점 계약', '호황', '수혜', '강세',
  ];

  static const _negativeKeywords = [
    '급락', '하락', '적자전환', '적자', '손실', '매출 감소', '영업이익 감소',
    '목표가 하향', '실적 부진', '수출 감소', '구조조정', '감원', '리콜',
    '과징금', '소송', '파업', '파산', '상장폐지', '제재', '규제 강화',
    '불황', '침체', '위기', '폭락', '약세', '악재',
  ];

  static final _symbolToStock = <String, Map<String, String>>{
    for (final v in _companyKeywords.values) v['symbol']!: v,
    '012450': {'symbol': '012450', 'name': '한화에어로스페이스'},
    '064350': {'symbol': '064350', 'name': '현대로템'},
    '079550': {'symbol': '079550', 'name': 'LIG넥스원'},
    '047810': {'symbol': '047810', 'name': '한국항공우주(KAI)'},
    '272210': {'symbol': '272210', 'name': '한화시스템'},
    '352820': {'symbol': '352820', 'name': 'HYBE'},
    '041510': {'symbol': '041510', 'name': 'SM엔터테인먼트'},
    '035900': {'symbol': '035900', 'name': 'JYP Ent.'},
    '122870': {'symbol': '122870', 'name': 'YG엔터테인먼트'},
    '035760': {'symbol': '035760', 'name': 'CJ ENM'},
    '034020': {'symbol': '034020', 'name': '두산에너빌리티'},
    '015760': {'symbol': '015760', 'name': '한국전력'},
    '006400': {'symbol': '006400', 'name': '삼성SDI'},
    '086520': {'symbol': '086520', 'name': '에코프로'},
    '011200': {'symbol': '011200', 'name': 'HMM'},
  };

  static NewsAnalysisResult analyze(String title, String summary) {
    final text = '$title $summary';

    // 1) Direct company name matches
    final directStocks = <String, Map<String, String>>{};
    for (final entry in _companyKeywords.entries) {
      if (text.contains(entry.key)) {
        directStocks.putIfAbsent(entry.value['symbol']!, () => entry.value);
      }
    }

    // 2) Sector rule matches
    final sectorMatches = <String, _SectorRule>{};
    for (final rule in _sectorRules) {
      for (final trigger in rule.triggers) {
        if (text.contains(trigger)) {
          for (final sym in rule.stocks) {
            sectorMatches.putIfAbsent(sym, () => rule);
          }
          break;
        }
      }
    }

    // 3) General sentiment
    int positiveScore = 0;
    int negativeScore = 0;
    String? topPositive;
    String? topNegative;

    for (final kw in _positiveKeywords) {
      if (text.contains(kw)) {
        positiveScore++;
        topPositive ??= kw;
      }
    }
    for (final kw in _negativeKeywords) {
      if (text.contains(kw)) {
        negativeScore++;
        topNegative ??= kw;
      }
    }

    final generalIsUp = positiveScore >= negativeScore;

    // Build predictions
    final seen = <String>{};
    final predictions = <StockPrediction>[];

    // Sector-based first (higher confidence)
    for (final entry in sectorMatches.entries) {
      final sym = entry.key;
      final rule = entry.value;
      if (seen.add(sym)) {
        final info = _symbolToStock[sym];
        if (info != null) {
          predictions.add(StockPrediction(
            symbol: sym,
            name: info['name']!,
            isUp: rule.isUp,
            reason: rule.reason,
          ));
        }
      }
    }

    // Direct company mentions not yet covered
    for (final entry in directStocks.entries) {
      final sym = entry.key;
      if (seen.add(sym)) {
        final reason = (positiveScore == 0 && negativeScore == 0)
            ? '언급됨 (방향 신호 불명확)'
            : generalIsUp
                ? '${topPositive ?? '긍정'} 관련 뉴스'
                : '${topNegative ?? '부정'} 관련 뉴스';
        predictions.add(StockPrediction(
          symbol: sym,
          name: entry.value['name']!,
          isUp: generalIsUp,
          reason: reason,
        ));
      }
    }

    // Summary text
    String summaryText;
    if (sectorMatches.isNotEmpty) {
      final sectors = sectorMatches.values
          .map((r) => r.reason.split('→').first.trim())
          .toSet()
          .take(2)
          .join(', ');
      summaryText = '$sectors 관련 뉴스입니다.';
    } else if (positiveScore > 0 || negativeScore > 0) {
      summaryText = generalIsUp
          ? '긍정 신호: ${topPositive ?? ''} 키워드 감지'
          : '부정 신호: ${topNegative ?? ''} 키워드 감지';
    } else {
      summaryText = '특정 종목·섹터 키워드를 찾지 못했습니다.';
    }

    return NewsAnalysisResult(
      summary: summaryText,
      predictions: predictions.take(4).toList(),
    );
  }
}

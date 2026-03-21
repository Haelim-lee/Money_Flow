export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  const query = req.query.query || '주식 증시';
  const display = req.query.display || '30';

  const url = `https://openapi.naver.com/v1/search/news.json?query=${encodeURIComponent(query)}&display=${display}&sort=date`;

  const response = await fetch(url, {
    headers: {
      'X-Naver-Client-Id': 'Y07FmNAOsd3ZuGhQ65WJ',
      'X-Naver-Client-Secret': 'dVI4L72W6I',
    },
  });

  if (!response.ok) {
    res.status(response.status).json({ error: '뉴스 로드 실패' });
    return;
  }

  const data = await response.json();
  res.status(200).json(data);
}

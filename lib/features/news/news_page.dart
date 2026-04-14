import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/widgets/custom_header.dart';
import '../../core/routes/app_routes.dart';

// ── โมเดลสำหรับบทความข่าวเดียว ──
class NewsArticle {
  final String articleId;
  final String title;
  final String description;
  final String content;
  final String url;
  final String? imageUrl;
  final String pubDate;
  final String sourceName;
  final List<String> categories;

  NewsArticle({
    required this.articleId,
    required this.title,
    required this.description,
    required this.content,
    required this.url,
    this.imageUrl,
    required this.pubDate,
    required this.sourceName,
    required this.categories,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      articleId: json['article_id'] ?? '',
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? 'No description available.',
      content: json['content'] ?? json['description'] ?? 'No content available.',
      url: json['link'] ?? '',
      imageUrl: json['image_url'],
      pubDate: json['pubDate'] ?? '',
      sourceName: json['source_name'] ?? 'Unknown Source',
      categories: List<String>.from(json['category'] ?? []),
    );
  }

  // 🚨 ใหม่: แปลงอ็อบเจกต์กลับเป็น JSON เพื่อเก็บลงหน่วยความจำมือถือ
  Map<String, dynamic> toJson() {
    return {
      'article_id': articleId,
      'title': title,
      'description': description,
      'content': content,
      'link': url,
      'image_url': imageUrl,
      'pubDate': pubDate,
      'source_name': sourceName,
      'category': categories,
    };
  }
}

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  List<NewsArticle> _articles = [];
  bool _isLoading = true;
  bool _hasError = false;

  static const String _apiKey = 'pub_15d7a58bd429466b9333339106b66d6d';

  @override
  void initState() {
    super.initState();
    _loadCachedNews(); // โหลดข่าวจากแคชทันที
    _fetchNews();      // ดึงข่าวใหม่ในพื้นหลัง
  }

  // 🚨 ฟังก์ชันใหม่: โหลดข่าวจากหน่วยความจำทันที
  Future<void> _loadCachedNews() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString('cached_news');
    
    if (cachedData != null) {
      final List decoded = jsonDecode(cachedData);
      setState(() {
        _articles = decoded.map((a) => NewsArticle.fromJson(a)).toList();
        _isLoading = false; 
      });
    }
  }

  Future<void> _fetchNews() async {
    setState(() {
      // แสดง spinner โหลดก็ต่อเมื่อยังไม่มีบทความแคช
      if (_articles.isEmpty) {
        _isLoading = true;
      }
      _hasError = false;
    });

    try {
      final uri = Uri.parse(
        'https://newsdata.io/api/1/latest'
        '?apikey=$_apiKey'
        '&q=cybersecurity AND malware AND ransomware OR hacking OR data breach OR cyberattacks OR cyberwarfare'
        '&category=technology,crime'
        '&language=en'
        '&size=10', 
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'] ?? [];

        // 1. กรองข่าว (เหมือนเกตเวย์ด้านหน้า)
        List<NewsArticle> incomingGoodArticles = results
            .map((a) => NewsArticle.fromJson(a))
            .where((a) => a.title.isNotEmpty && a.description.isNotEmpty)
            .where((a) {
              final t = a.title.toLowerCase();
              final d = a.description.toLowerCase();
              final s = a.sourceName.toLowerCase();

              // ตัดลิงก์ขยะ
              bool isGarbage = t.contains('summary') || t.contains('digest') || t.contains('roundup');
              // ตัดกับดัก paywall API
              bool isPaywall = d.contains('only available in paid plans') || d.contains('premium');
              // ตัดเว็บไซต์ที่รู้จักว่ามีปัญหา (เพิ่มได้หากเจออีก)
              bool isBlacklisted = s == 'ndtv' || s == 'gamingdeputy';

              return !isGarbage && !isPaywall && !isBlacklisted;
            }).toList();

        setState(() {
          // 2. รวมข่าวและลบซ้ำ
          List<NewsArticle> newUniqueArticles = [];
          
          for (var newArt in incomingGoodArticles) {
            // ตรวจสอบว่ามี ID นี้แล้วหรือยัง
            bool isDuplicateId = _articles.any((oldArt) => oldArt.articleId == newArt.articleId);
            // ตรวจสอบว่ามีหัวข้อนี้แล้วหรือยัง (ป้องกันข่าวซ้ำ)
            bool isDuplicateTitle = _articles.any((oldArt) => 
                oldArt.title.toLowerCase().trim() == newArt.title.toLowerCase().trim()
            );

            if (!isDuplicateId && !isDuplicateTitle) {
              newUniqueArticles.add(newArt); 
            }
          }

          // วางบทความใหม่ที่ไม่ซ้ำไว้ด้านบนสุดของฟีด
          _articles.insertAll(0, newUniqueArticles);

          // 3. จำกัดจำนวนแคช (อย่าให้โตเกิน 1,000 รายการจนเครื่องพัง)
          if (_articles.length > 20) {
            _articles = _articles.sublist(0, 20);
          }

          _isLoading = false;
        });

        // 4. บันทึกลงหน่วยความจำ
        final prefs = await SharedPreferences.getInstance();
        final String encodedData = jsonEncode(_articles.map((a) => a.toJson()).toList());
        await prefs.setString('cached_news', encodedData);

      } else {
        print('API ERROR: ${response.statusCode} - ${response.body}');

        setState(() {
          // ถ้า API ล้มเหลวแต่มีบทความแคชไว้แล้ว ให้ข้ามข้อผิดพลาดนี้
          if (_articles.isEmpty) _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('NETWORK ERROR: $e');
      setState(() {
        if (_articles.isEmpty) _hasError = true;
        _isLoading = false;
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: CustomHeader(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Security News',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: _fetchNews,
                  icon: const Icon(Icons.refresh, color: Color(0xFF00FFB2), size: 22),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00FFB2)));
    }

    if (_hasError || _articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            const Text('Could not load news', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchNews,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FFB2),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _articles.length + 1,
      itemBuilder: (context, index) {
        if (index == _articles.length) return const SizedBox(height: 80);
        final article = _articles[index];
        if (index == 0) return _buildHighlightCard(article, context);
        return _buildNewsItem(article, context);
      },
    );
  }

  Widget _buildHighlightCard(NewsArticle article, BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.newsDetail, arguments: article),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF131F1D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00FFB2).withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  article.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildImagePlaceholder(160),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00FFB2).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'LATEST',
                style: TextStyle(color: Color(0xFF00FFB2), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              article.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.3, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  article.sourceName,
                  style: const TextStyle(color: Color(0xFF00FFB2), fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(_formatDate(article.pubDate), style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsItem(NewsArticle article, BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.newsDetail, arguments: article),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: article.imageUrl != null
                  ? Image.network(
                      article.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildImagePlaceholder(80),
                    )
                  : _buildImagePlaceholder(80),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, height: 1.4, color: Colors.white),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        article.sourceName,
                        style: const TextStyle(color: Color(0xFF00FFB2), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Text(_formatDate(article.pubDate), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(12)),
      child: const Icon(Icons.article_outlined, color: Colors.grey),
    );
  }
}
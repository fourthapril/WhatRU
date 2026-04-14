import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../news/news_page.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class NewsDetailPage extends StatefulWidget {
  const NewsDetailPage({super.key});

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  bool _isFetching = true;
  String _fullText = "";
  bool _isInit = false;
  late NewsArticle article;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ดึงบทความที่ถูกส่งมาจากฟีดข่าวหลักอย่างปลอดภัย
    if (!_isInit) {
      article = ModalRoute.of(context)!.settings.arguments as NewsArticle;
      // เรียกใช้งานตัวขูด Jina ทันที
      _fetchFullArticle(article.url);
      _isInit = true;
    }
  }

  Future<void> _fetchFullArticle(String targetUrl) async {
    try {
      final uri = Uri.parse('https://r.jina.ai/$targetUrl');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'X-Retain-Images': 'none',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          String scrapedText = data['data']['content'] ?? '';
          
          // 🚨 ฟิลเตอร์ฮิวริสติกส์แบบเข้มข้นที่ปรับปรุงขึ้น 🚨
          int linkCount = scrapedText.split('](').length - 1;
          String lowerText = scrapedText.toLowerCase();
          
          // 1. เช็คความหนาแน่น: แม้ 5 ลิงก์ในข้อความสั้น ก็เป็นสัญญาณไม่ดี
          bool isMenuLeak = linkCount > 4 && scrapedText.length < 1200;
          
          // 2. เช็คคำสำคัญ: คำเมนูทั่วไปที่ไม่ควรขึ้นครองบทความไซเบอร์
          bool hasNavWords = linkCount > 2 && (
              lowerText.contains('cricket') || 
              lowerText.contains('movies') || 
              lowerText.contains('lifestyle') || 
              lowerText.contains('food') ||
              lowerText.contains('horoscope')
          );
          
          // 3. เช็คความยาว: บทความไซเบอร์แท้จริงไม่ค่อยสั้นกว่า 400 ตัวอักษร
          bool isTooShort = scrapedText.length < 400;

          // ผลการตัดสิน:
          if (scrapedText.isNotEmpty && !isMenuLeak && !hasNavWords && !isTooShort) {
            _fullText = scrapedText; // ผ่านทุกการตรวจสอบ!
          } else {
            _fullText = "The article is not available."; // เป็นขยะทางเนื้อหา แสดงคำอธิบายสั้นที่ปลอดภัยแทน
          }
          
          _isFetching = false;
        });
      } else {
        setState(() {
          _fullText = "The article is not available.";
          _isFetching = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fullText = "The article is not available.";
        _isFetching = false;
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
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E11),
      body: CustomScrollView(
        slivers: [
          // ── ส่วนหัวพร้อมภาพบทความจริง ──
          SliverAppBar(
            backgroundColor: const Color(0xFF0B0E11),
            expandedHeight: 220.0,
            floating: false,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: article.imageUrl != null
                  ? Image.network(
                      article.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildHeaderPlaceholder(),
                    )
                  : _buildHeaderPlaceholder(),
            ),
          ),

          // ── เนื้อหาบทความ ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // แสดงแบดจ์แหล่งที่มา
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FFB2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      article.sourceName.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF00FFB2),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ชื่อข่าว
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // วันที่
                  Text(
                    _formatDate(article.pubDate),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Colors.white.withOpacity(0.05)),
                  const SizedBox(height: 20),

                  // ── เนื้อหาแบบไดนามิก: แสดงสปินเนอร์หรือข้อความเต็ม ──
                  _isFetching
                      ? const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 40.0),
                          child: CircularProgressIndicator(color: Color(0xFF00FFB2)),
                        ),
                      )
                    : MarkdownBody(
                        data: _fullText,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(color: Colors.grey, fontSize: 15, height: 1.7),
                          h1: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          h2: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          h3: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          a: const TextStyle(color: Color(0xFF00FFB2), decoration: TextDecoration.underline),
                          listBullet: const TextStyle(color: Color(0xFF00FFB2)),
                        ),
                        // ทำให้ลิงก์สามารถคลิกได้จริง
                        onTapLink: (text, href, title) async {
                          if (href != null) {
                            final uri = Uri.parse(href);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          }
                        },
                      ),
                  
                  const SizedBox(height: 32),

                  // ── ปุ่มสำรอง "อ่านต้นฉบับ" ──
                  // แสดงเมื่อการสแกปจบลงแล้ว (แม้ว่าจะย้อนกลับไปใช้ข้อความสั้น)
                  if (!_isFetching)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse(article.url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.open_in_new, color: Colors.black, size: 16),
                        label: const Text(
                          'View Original Source',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FFB2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderPlaceholder() {
    return Container(
      color: const Color(0xFF131F1D),
      child: const Center(
        child: Icon(Icons.article_outlined, size: 80, color: Color(0xFF00FFB2)),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../core/widgets/custom_header.dart';
import '../../core/routes/app_routes.dart';

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text('Security News', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // ส่วนแสดงข่าวเด่น (Highlight News)
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.newsDetail),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131F1D),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00FFB2).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF00FFB2).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: const Text('BREAKING', style: TextStyle(color: Color(0xFF00FFB2), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'AI-Powered Threats Are Outpacing Traditional Antivirus Solutions by 3x',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // ส่วนแสดงรายการข่าวทั่วไป (News List)
                _buildNewsItem('New Zero-Day Vulnerability Found in Windows Kernel - Patch Now', context),
                _buildNewsItem('Ransomware "GhostExe" Spreads via Malicious PDF Attachments', context),
                _buildNewsItem('AWS Major Outage Hits Southeast Asia - Services Restored', context),
                _buildNewsItem('Google Fixes Critical Remote Code Execution Bug in Chrome', context),
                
                // เพิ่มพื้นที่ว่างด้านล่างเพื่อป้องกันการทับซ้อนกับ Navigation Bar
                const SizedBox(height: 80), 
              ],
            ),
          ),
        ],
      ),
    );
  }

  // วิดเจ็ตสำหรับแสดงผลรายการข่าวแต่ละรายการ
  Widget _buildNewsItem(String title, BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.newsDetail),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.image_outlined, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
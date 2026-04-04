import 'package:flutter/material.dart';

class TosPage extends StatelessWidget {
  const TosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080B0E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Terms of Service', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('WHATRU Terms of Service', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF00FFB2))),
            const SizedBox(height: 8),
            Text('Last updated: April 2026', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 24),
            
            // ส่วนที่ 1: ข้อความปฏิเสธความรับผิดชอบสำหรับโปรเจกต์เพื่อการศึกษา
            _buildSection(
              '1. Educational Project Disclaimer',
              'The WHATRU application is developed as part of the ITDS283 Mobile Application Development course at the Faculty of Information and Communication Technology (ICT), Mahidol University. This software is provided for educational and demonstration purposes. While we strive to provide accurate security assessments, the developers and the university are not liable for any damages or data loss resulting from the use of this application.',
            ),
            
            // ส่วนที่ 2: รายละเอียดการให้บริการ
            _buildSection(
              '2. Service Description',
              'WHATRU provides a file scanning and analysis service designed to detect potential malware, verify file extensions, and check against multiple security engines (such as VirusTotal). The "Safety Score" provided is an estimation based on our backend algorithms and third-party APIs. It does not guarantee absolute protection against all zero-day threats.',
            ),
            
            // ส่วนที่ 3: นโยบายความเป็นส่วนตัวและการจัดการข้อมูลไฟล์
            _buildSection(
              '3. Data Privacy & File Handling',
              'When you upload a file for scanning, the file is processed temporarily to generate a cryptographic hash and extract metadata. We do NOT store your personal files permanently on our servers unless explicitly moved to the "StrongBox" feature. Files sent for Deep Scan may be shared with our trusted security partners (e.g., VirusTotal) solely for threat analysis. Please avoid uploading files containing highly sensitive or confidential personal information.',
            ),
            
            // ส่วนที่ 4: ข้อกำหนดการใช้ API Key
            _buildSection(
              '4. API Key Usage',
              'Users have the option to provide their own VirusTotal API Key for scanning. By entering your API key, you agree to abide by VirusTotal\'s Terms of Service. WHATRU will securely store this key locally on your device and will only transmit it directly to the intended API endpoints.',
            ),
            
            // ส่วนที่ 5: การจำกัดความรับผิดชอบ
            _buildSection(
              '5. Limitation of Liability',
              'To the maximum extent permitted by applicable law, the student developers (Group 27) shall not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of profits or revenues, whether incurred directly or indirectly, or any loss of data, use, goodwill, or other intangible losses.',
            ),
            
            const SizedBox(height: 40),
            
            // ปุ่มยืนยันการรับทราบเงื่อนไข
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF161B22),
                  foregroundColor: const Color(0xFF00FFB2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFF00FFB2)),
                ),
                child: const Text('I Understand'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // วิดเจ็ตสำหรับจัดรูปแบบหัวข้อและเนื้อหาในแต่ละส่วนของข้อกำหนด
  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.6)),
        ],
      ),
    );
  }
}
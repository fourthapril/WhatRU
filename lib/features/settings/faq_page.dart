import 'package:flutter/material.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

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
        title: const Text('FAQ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Frequently Asked\nQuestions', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
          const SizedBox(height: 30),
          
          _buildFaqItem(
            'What is WHATRU?',
            'WHATRU is a mobile security application developed as a university project for ITDS283. It helps users verify the safety of files, detect malware, and keep track of scan histories using multi-engine threat detection.',
          ),
          _buildFaqItem(
            'How is the Safety Score calculated?',
            'The Safety Score is a composite metric that starts at 100%. Points are deducted based on findings such as polyglot detection, file extension mismatch, and the number of threat engines flagging the file via VirusTotal.',
          ),
          _buildFaqItem(
            'Are my scanned files kept on a server?',
            'No. Standard scans process your file temporarily in memory to generate a hash and query our threat databases. We do not keep copies of your files unless you choose to store them in your encrypted StrongBox.',
          ),
          _buildFaqItem(
            'What is the "StrongBox"?',
            'StrongBox is a secure, isolated storage area within the app. Files that you deem safe or want to monitor for unauthorized modifications can be saved here. The app tracks the file\'s integrity to ensure it hasn\'t been altered.',
          ),
          _buildFaqItem(
            'Why do I need a VirusTotal API Key?',
            'For advanced users using the "Deep Scan" feature, entering your own VirusTotal API key allows you to bypass public rate limits and get faster, more detailed multi-engine scan results directly from the provider.',
          ),
        ],
      ),
    );
  }

  // วิดเจ็ตสำหรับสร้างรายการคำถามที่พบบ่อย (FAQ Item) แบบขยายได้
  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Theme(
        // นำเส้นขอบเริ่มต้นของ ExpansionTile ออกเพื่อความสวยงาม
        data: ThemeData(dividerColor: Colors.transparent), 
        child: ExpansionTile(
          iconColor: const Color(0xFF00FFB2),
          collapsedIconColor: Colors.grey,
          title: Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 15),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Text(
                answer,
                style: const TextStyle(color: Colors.grey, height: 1.5, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
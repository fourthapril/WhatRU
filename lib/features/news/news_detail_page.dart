import 'package:flutter/material.dart';

class NewsDetailPage extends StatelessWidget {
  const NewsDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E11),
      body: CustomScrollView(
        slivers: [
          // ส่วนหัวของหน้าจอ (SliverAppBar) แสดงรูปภาพหรือไอคอนประกอบบทความ
          SliverAppBar(
            backgroundColor: const Color(0xFF0B0E11),
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B0E11), Color(0xFF131F1D)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.computer_outlined, size: 80, color: Color(0xFF00FFB2)),
                ),
              ),
            ),
          ),
          
          // ส่วนเนื้อหาบทความข่าว
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ป้ายกำกับหมวดหมู่ข่าว (Label)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FFB2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('BREAKING', style: TextStyle(color: Color(0xFF00FFB2), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  
                  // หัวข้อข่าว (Title)
                  const Text(
                    'AI-Powered Threats Are Outpacing Traditional Antivirus Solutions',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3),
                  ),
                  const SizedBox(height: 20),
                  
                  // เนื้อหาบทความส่วนที่ 1
                  const Text(
                    'A new wave of AI-generated malware is reshaping the cybersecurity landscape in 2026. Researchers at multiple security firms have confirmed that automated threat tools can now mutate faster than signature databases update, rendering traditional antivirus software increasingly ineffective.',
                    style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  
                  // กล่องเน้นข้อความสำคัญ (Highlight Quote)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      border: const Border(left: BorderSide(color: Color(0xFF00FFB2), width: 4)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '"These models don\'t just replicate — they adapt in real time, evading heuristics with every new execution cycle."',
                          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, height: 1.5),
                        ),
                        SizedBox(height: 12),
                        Text('- DR. LARA RIVERS, THREATSEC RESEARCH LAB', style: TextStyle(color: Color(0xFF00FFB2), fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // เนื้อหาบทความส่วนที่ 2
                  const Text(
                    'Security teams are urged to shift toward behavior-based detection and zero-trust architectures. Vendors like CrowdStrike and Palo Alto have already rolled out AI-native defense layers, but adoption remains low among SMEs.',
                    style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.6),
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
}
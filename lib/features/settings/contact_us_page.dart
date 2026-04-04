import 'package:flutter/material.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B0E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Contact Us', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Stack(
        children: [
          // เอฟเฟกต์เรืองแสงพื้นหลัง (Background Glow)
          Positioned(
            top: 100, left: -50,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF00FFB2).withOpacity(0.05), blurRadius: 100, spreadRadius: 40)],
              ),
            ),
          ),
          Positioned(
            bottom: 50, right: -50,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.05), blurRadius: 100, spreadRadius: 40)],
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                children: [
                  const Icon(Icons.code, size: 50, color: Color(0xFF00FFB2)),
                  const SizedBox(height: 16),
                  const Text('MEET THE DEVELOPERS', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                  const SizedBox(height: 8),
                  const Text(
                    'ITDS283 Mobile Application\nGroup 27',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3),
                  ),
                  const SizedBox(height: 40),

                  // การ์ดข้อมูลนักพัฒนา 1
                  _buildDeveloperCard(
                    name: 'Nantanan Pradubmuk',
                    studentId: '6787047',
                    email: 'nanthanan.pra@student.mahidol.ac.th',
                    role: 'Developer & UI/UX',
                    gradientColors: [const Color(0xFF00FFB2), const Color(0xFF008059)],
                  ),
                  const SizedBox(height: 24),

                  // การ์ดข้อมูลนักพัฒนา 2
                  _buildDeveloperCard(
                    name: 'Pannatat Pipopkullaporn',
                    studentId: '6787056',
                    email: 'pannatat.pip@student.mahidol.ac.th',
                    role: 'Developer & Backend',
                    gradientColors: [const Color(0xFF00E5FF), const Color(0xFF007A8C)],
                  ),
                  
                  const SizedBox(height: 50),
                  const Text('Faculty of ICT, Mahidol University', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // วิดเจ็ตสำหรับสร้างการ์ดข้อมูลนักพัฒนา
  Widget _buildDeveloperCard({
    required String name, required String studentId, required String email, required String role, required List<Color> gradientColors,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [gradientColors[0].withOpacity(0.5), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(2), // ความหนาของกรอบเกรเดียนท์ (Gradient Border)
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF131F1D), // สีพื้นหลังของการ์ด
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            // ส่วนรูปภาพโปรไฟล์ (Profile Image)
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                boxShadow: [
                  BoxShadow(color: gradientColors[0].withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF161B22), 
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    // ตำแหน่งสำหรับใส่รูปภาพโปรไฟล์จริง (Image.asset)
                    child: Icon(Icons.person, size: 40, color: Colors.grey), 
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // ส่วนข้อมูลส่วนบุคคลและบทบาท
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: gradientColors[0].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(role, style: TextStyle(color: gradientColors[0], fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text('ID: $studentId', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            
            // ส่วนข้อมูลอีเมล
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF080B0E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_outlined, color: gradientColors[0], size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      email,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
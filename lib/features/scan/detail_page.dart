import 'package:flutter/material.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E11),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Scan Result', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 30),
            
            // ส่วนแสดงไอคอนและข้อมูลพื้นฐานของไฟล์
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00FFB2), width: 4),
              ),
              child: const Center(child: Icon(Icons.picture_as_pdf, size: 40, color: Colors.redAccent)),
            ),
            const SizedBox(height: 20),
            const Text('Scan Complete: Low_Cortisol.pdf', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Size: 6.7 MB', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),

            // ส่วนแสดงผลการประเมินความเสี่ยง (Risk Assessment)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Risk Assessment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            _buildAssessmentItem('File Extension Verification', 'Extension matches file type', 'Safe', const Color(0xFF00FFB2)),
            _buildAssessmentItem('Polyglot Detection', 'Not found hidden script', 'Safe', const Color(0xFF00FFB2)),
            _buildAssessmentItem('Virus Total Engines', '2/70 engines detected threats', 'Safe', const Color(0xFF00FFB2)),
            const SizedBox(height: 30),

            // ส่วนแสดงคะแนนความปลอดภัยภาพรวม (Safety Score)
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                children: [
                  TextSpan(text: 'Safety Score: '),
                  TextSpan(text: '100', style: TextStyle(color: Color(0xFF00FFB2))),
                  TextSpan(text: '/100'),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // ปุ่มสำหรับบันทึกไฟล์ (Save Action)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FFB2),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save to StrongBox', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // วิดเจ็ตสำหรับแสดงรายการการประเมินแต่ละหัวข้อ
  Widget _buildAssessmentItem(String title, String subtitle, String status, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
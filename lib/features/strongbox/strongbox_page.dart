import 'package:flutter/material.dart';
import '../../core/widgets/custom_header.dart';

class StrongBoxPage extends StatelessWidget {
  const StrongBoxPage({super.key});

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
          
          // ส่วนแสดงสรุปสถานะการจัดเก็บไฟล์ (Summary Card)
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF131F1D),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FFB2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lock_outline, color: Color(0xFF00FFB2), size: 30),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('My StrongBox', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Keep your files safe', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                // ตัวเลขแสดงจำนวนไฟล์แยกตามสถานะ
                _buildBadge('4', const Color(0xFF00FFB2)), // จำนวนไฟล์ปลอดภัย
                const SizedBox(width: 8),
                _buildBadge('1', const Color(0xFFFF4B6C)), // จำนวนไฟล์ที่พบความเสี่ยง
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Stored Files', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Sort by date', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          
          // รายการไฟล์ที่ถูกจัดเก็บในระบบ
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildStoredFile('Setup_installer_v2.exe', 'ALERT', const Color(0xFFFF4B6C)),
                _buildStoredFile('Company_Report_Q1.pdf', 'SECURE', const Color(0xFF00FFB2)),
                _buildStoredFile('Photo_backup_march.zip', 'SECURE', const Color(0xFF00FFB2)),
                _buildStoredFile('Employee_list_2026.xlsx', 'SECURE', const Color(0xFF00FFB2)),
                const SizedBox(height: 80), // พื้นที่ว่างส่วนท้ายหน้าจอ
              ],
            ),
          ),
        ],
      ),
    );
  }

  // วิดเจ็ตสำหรับแสดงป้ายสถานะจำนวนไฟล์ (Badge)
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }

  // วิดเจ็ตสำหรับแสดงข้อมูลไฟล์แต่ละรายการที่จัดเก็บไว้
  Widget _buildStoredFile(String title, String status, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(20),
        border: status == 'ALERT' ? Border.all(color: color.withOpacity(0.3)) : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.insert_drive_file_outlined, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ),
              // ป้ายกำกับสถานะความปลอดภัยของไฟล์
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(status == 'SECURE' ? Icons.check_circle : Icons.warning, color: color, size: 12),
                    const SizedBox(width: 4),
                    Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          
          // ปุ่มดำเนินการสำหรับจัดการไฟล์ (Relocate และ Re-verify)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.folder_copy_outlined, size: 14, color: Colors.grey),
                label: const Text('Relocate', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.refresh, size: 14, color: color),
                label: Text('Re-verify', style: TextStyle(color: color, fontSize: 12)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: color.withOpacity(0.5))),
              ),
            ],
          )
        ],
      ),
    );
  }
}
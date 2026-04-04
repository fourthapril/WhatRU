import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

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
        title: const Text('Notifications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Mark read', style: TextStyle(color: Color(0xFF00FFB2), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          const Text('Today', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          // รายการแจ้งเตือนประเภท Threat
          _buildNotificationItem(
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFFF4B6C),
            iconBgColor: const Color(0xFFFF4B6C).withOpacity(0.1),
            title: 'Threat Detected!',
            message: 'Setup_v2.exe contains a potential malware. Please check your StrongBox.',
            time: '2m ago',
            isUnread: true,
          ),
          
          // รายการแจ้งเตือนประเภท Safe
          _buildNotificationItem(
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFF00FFB2),
            iconBgColor: const Color(0xFF00FFB2).withOpacity(0.1),
            title: 'Scan Complete',
            message: 'Document_2024.pdf is safe to open.',
            time: '15m ago',
            isUnread: true,
          ),
          const SizedBox(height: 20),
          
          const Text('Yesterday', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          // รายการแจ้งเตือนประเภท System Update
          _buildNotificationItem(
            icon: Icons.system_update,
            iconColor: Colors.blueAccent, 
            iconBgColor: Colors.blueAccent.withOpacity(0.1),
            title: 'System Update Available',
            message: 'v2.4.1 is ready to install. Update now for better security.',
            time: '1d ago',
            isUnread: false,
          ),
          
          // รายการแจ้งเตือนประเภท Report
          _buildNotificationItem(
            icon: Icons.article_outlined,
            iconColor: Colors.purpleAccent,
            iconBgColor: Colors.purpleAccent.withOpacity(0.1),
            title: 'Weekly Security Report',
            message: 'You have scanned 15 files this week. Keep your device safe!',
            time: '1d ago',
            isUnread: false,
          ),
        ],
      ),
    );
  }

  // วิดเจ็ตสำหรับแสดงผลรายการแจ้งเตือนแต่ละรายการ
  Widget _buildNotificationItem({
    required IconData icon, required Color iconColor, required Color iconBgColor,
    required String title, required String message, required String time, required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread ? const Color(0xFF161B22) : const Color(0xFF0B0E11),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isUnread ? iconColor.withOpacity(0.2) : Colors.white.withOpacity(0.05), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ใช้ Expanded ครอบ Title เพื่อป้องกันปัญหาข้อความทับซ้อนกับเวลา
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(message, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          
          // จุดแสดงสถานะการแจ้งเตือนที่ยังไม่ได้อ่าน
          if (isUnread) ...[
            const SizedBox(width: 12),
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 8, height: 8,
              decoration: const BoxDecoration(color: Color(0xFF00FFB2), shape: BoxShape.circle),
            ),
          ]
        ],
      ),
    );
  }
}
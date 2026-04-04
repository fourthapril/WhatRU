import 'package:flutter/material.dart';

import '../features/strongbox/strongbox_page.dart';
import '../features/history/history_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/scan/scan_page.dart';
import '../features/news/news_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // กำหนดดัชนีเริ่มต้นที่หน้า Dashboard (Index 2)
  int _currentIndex = 2;

  // ฟังก์ชันสำหรับเปลี่ยนแท็บการแสดงผล
  void _changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // รายการหน้าจอทั้งหมดภายในระบบ Navigation
    final List<Widget> pages = [
      const StrongBoxPage(), // Index 0: ส่วนจัดเก็บไฟล์ปลอดภัย
      const HistoryPage(),   // Index 1: ประวัติการสแกน
      
      // Index 2: หน้าหลัก พร้อม Callback สำหรับการนำทางภายในหน้า
      DashboardPage(
        onQuickScan: () => _changeTab(3), 
        onSeeAll: () => _changeTab(1),    
      ), 
      
      const ScanPage(),      // Index 3: หน้าดำเนินการสแกน
      const NewsPage(),      // Index 4: ข่าวสารความปลอดภัย
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E11),
      // ใช้ IndexedStack เพื่อรักษา State ของแต่ละหน้าขณะสลับแท็บ
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ส่วนประกอบแถบเมนูนำทางด้านล่าง (Bottom Navigation Bar)
  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20, top: 10),
      color: const Color(0xFF0B0E11),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0E11),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.inventory_2_outlined, 0), 
            _buildNavItem(Icons.access_time, 1),           
            _buildCenterNavItem(2),                       
            _buildNavItem(Icons.search, 3),               
            _buildNavItem(Icons.article_outlined, 4),     
          ],
        ),
      ),
    );
  }

  // วิดเจ็ตสำหรับสร้างรายการไอคอนนำทางทั่วไป
  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = _currentIndex == index;
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? const Color(0xFF00FFB2) : Colors.grey,
        size: 26,
      ),
      onPressed: () => _changeTab(index),
    );
  }

  // วิดเจ็ตสำหรับสร้างปุ่มหน้าหลัก (Dashboard) บริเวณกึ่งกลาง
  Widget _buildCenterNavItem(int index) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _changeTab(index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00FFB2).withOpacity(0.1) : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFF00FFB2) : Colors.transparent, 
            width: 1
          ),
        ),
        child: Icon(
          Icons.home_filled, 
          color: isSelected ? const Color(0xFF00FFB2) : Colors.grey,
          size: 26,
        ),
      ),
    );
  }
}
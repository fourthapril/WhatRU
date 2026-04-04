import 'package:flutter/material.dart';
import '../core/routes/app_routes.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    // หน่วงเวลาการแสดงผลหน้า Loading 2.5 วินาทีก่อนนำทางไปยังหน้าหลัก
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.main);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B0E), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ส่วนแสดงสัญลักษณ์แอปพลิเคชัน (Folder และ Malware Icon)
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const Icon(
                  Icons.folder_outlined,
                  size: 100,
                  color: Colors.white,
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF080B0E), 
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.coronavirus_outlined,
                    size: 45,
                    color: Color(0xFF00FFB2), 
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            
            // ส่วนแสดงสถานะการโหลด (Progress Indicator)
            const CircularProgressIndicator(
              color: Color(0xFF00FFB2),
            ),
            const SizedBox(height: 16),
            
            // ข้อความแจ้งสถานะการเข้าสู่ระบบ
            const Text(
              'Loading WHATRU...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
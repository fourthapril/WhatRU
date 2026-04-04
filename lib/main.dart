import 'package:flutter/material.dart';
import 'core/routes/app_routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // ตรวจสอบความพร้อมของ Flutter Engine ก่อนเริ่มต้นทำงาน
  WidgetsFlutterBinding.ensureInitialized();
  
  // เริ่มต้นการทำงานของ Firebase ตามการตั้งค่าปัจจุบัน
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  runApp(const WhatRuApp());
}

class WhatRuApp extends StatelessWidget {
  const WhatRuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WHATRU Security',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF080B0E),

        // กำหนดธีมเริ่มต้นสำหรับ AppBar เพื่อให้มีความสม่ำเสมอทั้งแอปพลิเคชัน
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0, // ปิดการเปลี่ยนระดับเลเยอร์เมื่อมีการเลื่อนหน้าจอ
          surfaceTintColor: Colors.transparent, // ปิดการแสดงสีเหลือบ (Tint) เพื่อคงความมินิมอล
        ),

        // กำหนดชุดสีหลักของแอปพลิเคชัน (Primary & Secondary Colors)
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FFB2),
          secondary: Color(0xFFFF4B6C),
        ),
      ),
      // เริ่มต้นด้วยหน้าจอ Loading และกำหนดรายการเส้นทาง (Routes) ทั้งหมด
      initialRoute: AppRoutes.loading,
      routes: AppRoutes.getRoutes(),
    );
  }
}
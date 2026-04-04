import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ScanLimitService {
  static const int maxFreeScans = 10; // กำหนดโควตาสแกนฟรีสูงสุดต่อวัน

  // ตรวจสอบสิทธิ์การสแกน
  static Future<bool> canScan() async {
    // ตรวจสอบสถานะผู้ใช้และการสมัคร PRO
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          bool isPro = (doc.data() as Map<String, dynamic>)['isPro'] ?? false;
          if (isPro) return true; // คืนค่า true ทันทีสำหรับผู้ใช้ PRO (ใช้งานได้ไม่จำกัด)
        }
      } catch (e) {
        // หากเกิดข้อผิดพลาด ให้ข้ามไปตรวจสอบโควตาสแกนฟรี
      }
    }

    // ตรวจสอบโควตาจาก SharedPreferences สำหรับผู้ใช้ฟรี
    return await _checkLocalLimit();
  }

  // บันทึกการใช้งานสแกนเพิ่ม 1 ครั้ง
  static Future<void> incrementScan() async {
    // ยกเว้นการนับโควตาสำหรับผู้ใช้ PRO
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && (doc.data() as Map<String, dynamic>)['isPro'] == true) {
          return; 
        }
      } catch (_) {}
    }

    // บันทึกการใช้งานสำหรับผู้ใช้ฟรี
    final prefs = await SharedPreferences.getInstance();
    String today = DateTime.now().toIso8601String().split('T').first;
    String? savedDate = prefs.getString('scan_date');
    int currentCount = prefs.getInt('scan_count') ?? 0;

    if (savedDate != today) {
      // เริ่มนับโควตาใหม่หากเป็นวันใหม่
      await prefs.setString('scan_date', today);
      await prefs.setInt('scan_count', 1);
    } else {
      // เพิ่มจำนวนการใช้งานในวันปัจจุบัน
      await prefs.setInt('scan_count', currentCount + 1);
    }
  }

  // ตรวจสอบจำนวนโควตาที่เหลือในเครื่อง
  static Future<bool> _checkLocalLimit() async {
    final prefs = await SharedPreferences.getInstance();
    String today = DateTime.now().toIso8601String().split('T').first; // รูปแบบวันที่: YYYY-MM-DD
    String? savedDate = prefs.getString('scan_date');
    int currentCount = prefs.getInt('scan_count') ?? 0;

    // รีเซ็ตโควตาเมื่อขึ้นวันใหม่
    if (savedDate != today) {
      return true; 
    }

    // ตรวจสอบว่าใช้งานเกินขีดจำกัดหรือไม่
    return currentCount < maxFreeScans; 
  }
  
  static Future<int> getRemainingScans() async {
    User? user = FirebaseAuth.instance.currentUser;
    
    // 1. ตรวจสอบสถานะ PRO
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && (doc.data() as Map<String, dynamic>)['isPro'] == true) {
          return -1; // ใช้ค่า -1 เพื่อระบุสถานะใช้งานไม่จำกัด (Unlimited)
        }
      } catch (_) {}
    }

    // 2. ตรวจสอบข้อมูลโควตาในเครื่อง
    final prefs = await SharedPreferences.getInstance();
    String today = DateTime.now().toIso8601String().split('T').first;
    String? savedDate = prefs.getString('scan_date');
    int currentCount = prefs.getInt('scan_count') ?? 0;

    if (savedDate != today) {
      return maxFreeScans; // คืนค่าโควตาสูงสุดหากเป็นวันใหม่
    }
    
    int remaining = maxFreeScans - currentCount;
    return remaining > 0 ? remaining : 0; // คืนค่าโควตาที่เหลือ (ไม่ต่ำกว่า 0)
  }

  static Future<int> getLocalRemainingScans() async {
    final prefs = await SharedPreferences.getInstance();
    String today = DateTime.now().toIso8601String().split('T').first;
    String? savedDate = prefs.getString('scan_date');
    int currentCount = prefs.getInt('scan_count') ?? 0;

    if (savedDate != today) {
      return maxFreeScans; 
    }
    int remaining = maxFreeScans - currentCount;
    return remaining > 0 ? remaining : 0;
  }
  
  static final ValueNotifier<int> refreshNotifier = ValueNotifier<int>(0);

  static void notifyRefresh() {
    refreshNotifier.value++;
  }
}
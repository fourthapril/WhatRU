import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/scan_limit_service.dart';

class QuotaStatusWidget extends StatelessWidget {
  final String type; 
  
  const QuotaStatusWidget({super.key, this.type = 'bar'});

  @override
  Widget build(BuildContext context) {
    // ใช้ ValueListenableBuilder เพื่อรองรับการสั่งรีเฟรชหน้าจอแบบ Manual
    return ValueListenableBuilder<int>(
      valueListenable: ScanLimitService.refreshNotifier,
      builder: (context, _, __) {
        final user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          return _buildFutureLocalQuota();
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, snapshot) {
            bool isPro = false;
            if (snapshot.hasData && snapshot.data!.exists) {
               isPro = (snapshot.data!.data() as Map<String, dynamic>)['isPro'] ?? false;
            }

            if (isPro) {
               return type == 'bar' ? _buildBarUI(-1) : _buildTextUI(-1);
            } else {
               return _buildFutureLocalQuota();
            }
          },
        );
      },
    );
  }

  // วิดเจ็ตสำหรับแสดงโควตาคงเหลือของผู้ใช้ฟรี
  Widget _buildFutureLocalQuota() {
    return FutureBuilder<int>(
      // ดึงข้อมูลโควตาคงเหลือจาก Local Storage
      future: ScanLimitService.getLocalRemainingScans(),
      builder: (context, snapshot) {
         // กำหนดค่าเริ่มต้นเป็น 10 ในระหว่างรอโหลดข้อมูล
         int remaining = snapshot.data ?? 10;
         return type == 'bar' ? _buildBarUI(remaining) : _buildTextUI(remaining);
      }
    );
  }

  // ส่วนแสดงผล UI รูปแบบ Progress Bar
  Widget _buildBarUI(int remaining) {
     String limitText = remaining == -1 ? "PRO Plan: Unlimited Scans" : "$remaining / 10 Free Scans Remaining";
     double progress = remaining == -1 ? 1.0 : (remaining / 10);
     Color progressColor = remaining == -1 ? const Color(0xFF00FFB2) : (remaining <= 2 ? const Color(0xFFFF4B6C) : const Color(0xFF00E5FF));

     return Column(
       children: [
         Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             const Text('Daily Limit', style: TextStyle(color: Colors.grey, fontSize: 12)),
             Text(limitText, style: TextStyle(color: progressColor, fontSize: 12, fontWeight: FontWeight.bold)),
           ],
         ),
         const SizedBox(height: 8),
         ClipRRect(
           borderRadius: BorderRadius.circular(10),
           child: LinearProgressIndicator(
             value: progress,
             minHeight: 8,
             backgroundColor: const Color(0xFF161B22),
             valueColor: AlwaysStoppedAnimation<Color>(progressColor),
           ),
         ),
         if (remaining != -1 && remaining <= 3)
           Padding(
             padding: const EdgeInsets.only(top: 16),
             child: Text(
               'You are running low on free scans.\nUpgrade to PRO to stay protected.',
               textAlign: TextAlign.center,
               style: TextStyle(color: Colors.red[300], fontSize: 11),
             ),
           ),
       ],
     );
  }

  // ส่วนแสดงผล UI รูปแบบข้อความ
  Widget _buildTextUI(int remaining) {
    if (remaining == -1) {
      return const Text('PRO: Unlimited Scans', style: TextStyle(color: Color(0xFF00FFB2), fontSize: 12, fontWeight: FontWeight.bold));
    }
    return Text('Free Scans left: $remaining/10', 
        style: TextStyle(color: remaining <= 2 ? const Color(0xFFFF4B6C) : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold));
  }
}
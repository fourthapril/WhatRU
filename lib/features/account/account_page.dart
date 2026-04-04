import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/routes/app_routes.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ตรวจสอบสถานะการเข้าสู่ระบบของผู้ใช้
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF080B0E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Your Account', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          // แสดงปุ่มออกจากระบบ (Log out) เฉพาะเมื่อผู้ใช้เข้าสู่ระบบแล้ว
          if (user != null)
            IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFFFF4B6C), size: 22),
              onPressed: () {
                // แสดงหน้าต่างยืนยันการออกจากระบบ
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF161B22), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('Log out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    content: const Text('Are you sure you want to log out?', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context), // ปิดหน้าต่างการแจ้งเตือน
                        child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context); // ปิดหน้าต่างการแจ้งเตือน
                          await FirebaseAuth.instance.signOut(); // ดำเนินการออกจากระบบ
                          if (context.mounted) Navigator.pop(context); // นำทางกลับไปยังหน้าก่อนหน้า
                        },
                        child: const Text('LOG OUT', style: TextStyle(color: Color(0xFFFF4B6C), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      // แสดงมุมมองผู้เยี่ยมชมหากยังไม่เข้าสู่ระบบ หรือแสดงข้อมูลบัญชีหากเข้าสู่ระบบแล้ว
      body: user == null ? _buildGuestView(context) : _buildLoggedInView(user.uid, context),
    );
  }

  // มุมมองสำหรับผู้ใช้ที่ยังไม่ได้เข้าสู่ระบบ (Guest View)
  Widget _buildGuestView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF161B22),
                boxShadow: [BoxShadow(color: const Color(0xFF00FFB2).withOpacity(0.1), blurRadius: 40, spreadRadius: 10)],
              ),
              child: const Icon(Icons.lock_person_outlined, size: 60, color: Color(0xFF00FFB2)),
            ),
            const SizedBox(height: 32),
            const Text('Access Restricted', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            const Text(
              'Please log in or create an account to view your profile and sync your scan history across devices.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00FFB2), Color(0xFF00E5FF)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.createAccount),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('CREATE ACCOUNT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[800]!),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('LOG IN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // มุมมองสำหรับผู้ใช้ที่เข้าสู่ระบบแล้ว โดยดึงข้อมูลจาก Firestore
  Widget _buildLoggedInView(String uid, BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      // ดึงข้อมูลผู้ใช้แบบ Real-time จาก Firestore ตาม UID
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00FFB2)));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('User data not found.', style: TextStyle(color: Colors.grey)));
        }

        // ประมวลผลข้อมูลผู้ใช้จาก Firestore
        var userData = snapshot.data!.data() as Map<String, dynamic>;
        String username = userData['username'] ?? 'User';
        String email = userData['email'] ?? '';
        bool isPro = userData['isPro'] ?? false;
        String planName = userData['planName'] ?? 'Free Plan';
        
        // จัดรูปแบบวันที่สมัครสมาชิก
        String joinDate = "Recently";
        if (userData['createdAt'] != null) {
          DateTime date = (userData['createdAt'] as Timestamp).toDate();
          joinDate = "${date.day}/${date.month}/${date.year}"; 
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: isPro ? const Color(0xFF00FFB2) : Colors.grey, width: 3),
                        color: const Color(0xFF161B22),
                      ),
                      child: Icon(Icons.person, size: 50, color: isPro ? const Color(0xFF00FFB2) : Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Text(username, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 12),
                    
                    // ป้ายแสดงสถานะการสมัครสมาชิก
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPro ? const Color(0xFF00FFB2).withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isPro ? const Color(0xFF00FFB2) : Colors.grey),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isPro ? Icons.star : Icons.shield_outlined, color: isPro ? const Color(0xFF00FFB2) : Colors.grey, size: 14),
                          const SizedBox(width: 6),
                          Text(planName.toUpperCase(), style: TextStyle(color: isPro ? const Color(0xFF00FFB2) : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // แสดงวันที่เริ่มต้นเป็นสมาชิก
                    Text('Member since: $joinDate', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              Row(
                children: [
                  Expanded(child: _buildStatBox('Files Scanned', '0', Icons.shield_outlined, const Color(0xFF00E5FF))),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatBox('Threats Found', '0', Icons.warning_amber_rounded, const Color(0xFFFF4B6C))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatBox(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
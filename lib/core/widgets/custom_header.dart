import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomHeader extends StatelessWidget {
  const CustomHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'WHATRU',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        Row(
          children: [
            // ปุ่มการแจ้งเตือน (Notifications)
            _buildHeaderIcon(
              icon: Icons.notifications_none_outlined,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.notifications),
            ),
            const SizedBox(width: 12),

            // ปุ่ม Subscription (สถานะพรีเมียม)
            _buildHeaderIcon(
              icon: Icons.rocket_launch_outlined,
              onTap: () {
                // ตรวจสอบสถานะการเข้าสู่ระบบของผู้ใช้
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  // กรณีเข้าสู่ระบบแล้ว นำทางไปยังหน้าจัดการ Subscription
                  Navigator.pushNamed(context, AppRoutes.subscription);
                } else {
                  // กรณียังไม่เข้าสู่ระบบ นำทางไปยังหน้าสร้างบัญชี (Create Account)
                  Navigator.pushNamed(context, AppRoutes.createAccount);
                }
              },
            ),
            const SizedBox(width: 12),

            // ปุ่มตั้งค่า (Settings)
            _buildHeaderIcon(
              icon: Icons.settings_outlined,
              onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: Colors.grey[400]),
      ),
    );
  }
}
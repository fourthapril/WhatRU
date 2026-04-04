import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B0E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Setting', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildMenuTile(context, Icons.person_outline, 'Your Account', const Color(0xFF00FFB2), AppRoutes.account),
          _buildMenuTile(context, Icons.rocket_launch_outlined, 'Your Subscription', Colors.purpleAccent, AppRoutes.subscription),
          
          // เชื่อมโยงเส้นทางไปยังหน้าจอเพิ่มเติม
          _buildMenuTile(context, Icons.description_outlined, 'Term of Service', Colors.blue, AppRoutes.tos),
          _buildMenuTile(context, Icons.help_outline, 'FAQ', Colors.orange, AppRoutes.faq),
          _buildMenuTile(context, Icons.headset_mic_outlined, 'Contact Us', Colors.yellow, AppRoutes.contact),
          
          const Spacer(),
          const Padding(
            padding: EdgeInsets.only(bottom: 50),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Icon(Icons.folder_outlined, size: 100, color: Colors.white24),
                Icon(Icons.coronavirus_outlined, size: 40, color: Colors.white24),
              ],
            ),
          )
        ],
      ),
    );
  }

  // วิดเจ็ตสำหรับสร้างรายการเมนูแต่ละแถว
  Widget _buildMenuTile(BuildContext context, IconData icon, String title, Color iconColor, String routeName) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () => Navigator.pushNamed(context, routeName),
      ),
    );
  }
}
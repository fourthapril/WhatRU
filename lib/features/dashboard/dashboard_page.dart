import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart'; 
import '../../core/widgets/custom_header.dart';
import '../../core/widgets/quota_status_widget.dart'; // นำเข้า Widget สำหรับแสดงสถานะโควตา
import '../../core/services/scan_limit_service.dart'; 
import '../../core/routes/app_routes.dart'; 

class DashboardPage extends StatefulWidget {
  final VoidCallback? onQuickScan;
  final VoidCallback? onSeeAll;

  const DashboardPage({super.key, this.onQuickScan, this.onSeeAll});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // ข้อมูลสถิติจำลองสำหรับการแสดงผล
  final int totalScanned = 1248;
  final int totalThreats = 3;
  final double securityScore = 0.87; 

  // จัดการกระบวนการสแกนแบบด่วน (Quick Scan)
  Future<void> _handleQuickScan() async {
    bool canScan = await ScanLimitService.canScan();

    if (!canScan) {
      _showUpgradeDialog();
    } else {
      widget.onQuickScan?.call();
    }
  }

  // แสดงหน้าต่างแจ้งเตือนเมื่อโควตาหมด
  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF4B6C)),
            SizedBox(width: 8),
            Text('Daily Limit Reached', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'You have used all 10 free scans for today.\n\nUpgrade to WHATRU PRO for UNLIMITED real-time threat detection.',
          style: TextStyle(color: Colors.grey, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('MAYBE LATER', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.subscription);
            },
            child: const Text('UPGRADE TO PRO', style: TextStyle(color: Color(0xFF00FFB2), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double cleanPercentage = ((totalScanned - totalThreats) / totalScanned) * 100;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomHeader(),
            const SizedBox(height: 30),

            _buildSecurityCard(),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: _buildStatCard(totalScanned.toString(), 'SCANNED', Icons.shield_outlined, null)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(totalThreats.toString(), 'THREATS', Icons.warning_amber_rounded, Colors.yellow)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('${cleanPercentage.toStringAsFixed(1)}%', 'CLEAN', Icons.check_circle_outline, const Color(0xFF00FFB2))),
              ],
            ),
            const SizedBox(height: 20),

            _buildUpdateBanner(),
            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Scans', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                TextButton(
                  onPressed: widget.onSeeAll, 
                  child: const Text('See all', style: TextStyle(color: Color(0xFF00FFB2), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildScanItem('Document_2024.pdf', '2.4 MB · 2m ago', 'Clean', const Color(0xFF00FFB2)),
            _buildScanItem('Setup_v2.exe', '18.1 MB · 15m ago', 'Threat', const Color(0xFFFF4B6C)),
            _buildScanItem('Photo_backup.zip', '340 MB · 1h ago', 'Clean', const Color(0xFF00FFB2)),
            _buildScanItem('Muahahah.zip', '340 MB · 1h ago', 'Clean', const Color(0xFF00FFB2)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF131F1D),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFF00FFB2).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100, height: 100,
                child: CircularProgressIndicator(
                  value: securityScore, 
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00FFB2)),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${(securityScore * 100).toInt()}%', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Text('SECURE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF00FFB2), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    const Text('PROTECTED', style: TextStyle(color: Color(0xFF00FFB2), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Your device\nis safe', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.2, color: Colors.white)),
                const SizedBox(height: 8),

                // แสดงสถานะโควตาในรูปแบบข้อความ
                const QuotaStatusWidget(type: 'text'),

                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _handleQuickScan, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF), 
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Quick Scan', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1618), 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFF4B6C).withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFFF4B6C), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    const Text('SYSTEM SETTINGS', style: TextStyle(color: Color(0xFFFF4B6C), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Check OS security in settings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              AppSettings.openAppSettings(type: AppSettingsType.security);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B6C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Open', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String val, String label, IconData icon, Color? iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor ?? Colors.grey[400], size: 24),
          const SizedBox(height: 12),
          Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildScanItem(String name, String info, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2524),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.description_outlined, color: Colors.grey[400]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                const SizedBox(height: 4),
                Text(info, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
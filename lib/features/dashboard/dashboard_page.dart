import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/widgets/custom_header.dart';
import '../../core/widgets/quota_status_widget.dart';
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

  // ── ดึงรหัสสัปดาห์ปัจจุบัน เช่น "2026-W15" ──
  String _currentWeekId() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(firstDay).inDays;
    final weekNum =
        ((dayOfYear + firstDay.weekday - 1) / 7).ceil();
    return '${now.year}-W$weekNum';
  }

  // ── แปลง Timestamp จาก Firestore ให้เป็นข้อความเวลาสัมพัทธ์ ──
  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final time = timestamp.toDate();
    final diff = now.difference(time);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays == 1)    return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  // ── แปลงประเภทไฟล์เป็นไอคอน ──
  IconData _fileIcon(String? fileType) {
    switch (fileType) {
      case 'PDF':  return Icons.picture_as_pdf;
      case 'EXE':
      case 'ELF':  return Icons.terminal;
      case 'ZIP':  return Icons.folder_zip;
      case 'JPG':
      case 'PNG':  return Icons.image;
      case 'MP4':  return Icons.movie;
      case 'TEXT': return Icons.code;
      default:     return Icons.insert_drive_file;
    }
  }

  // ── แปลงคะแนนความปลอดภัยเป็นสี ──
  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF00FFB2);
    if (score >= 50) return Colors.amber;
    return const Color(0xFFFF4B6C);
  }

  Future<void> _handleQuickScan() async {
    final canScan = await ScanLimitService.canScan();
    if (!canScan) {
      _showUpgradeDialog();
    } else {
      widget.onQuickScan?.call();
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFFF4B6C)),
            SizedBox(width: 8),
            Text('Daily Limit Reached',
                style:
                    TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'You have used all 10 free scans for today.\n\nUpgrade to WHATRU PRO for UNLIMITED real-time threat detection.',
          style: TextStyle(color: Colors.grey, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('MAYBE LATER',
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.subscription);
            },
            child: const Text('UPGRADE TO PRO',
                style: TextStyle(
                    color: Color(0xFF00FFB2),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomHeader(),
            const SizedBox(height: 30),

            // ── การ์ดความปลอดภัยและสถิติประจำสัปดาห์จาก Firestore ──
            user == null
                ? _buildGuestSecurityCard()
                : StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('weeklyStats')
                        .doc(_currentWeekId())
                        .snapshots(),
                    builder: (context, weekSnap) {
                      // สถิติประจำสัปดาห์ — ค่าเริ่มต้นเป็น 100 ถ้าไม่มีข้อมูล
                      int totalScans   = 0;
                      int avgScore     = 100;
                      int threatCount  = 0;
                      int safeCount    = 0;

                      if (weekSnap.hasData &&
                          weekSnap.data!.exists) {
                        final w = weekSnap.data!.data()
                            as Map<String, dynamic>;
                        totalScans  = w['totalScans']   ?? 0;
                        avgScore    = w['averageScore'] ?? 100;
                        threatCount = w['threatCount']  ?? 0;
                        safeCount   = w['safeCount']    ?? 0;
                      }

                      final double scoreRatio =
                          avgScore / 100.0;
                      final Color scoreColor =
                          _scoreColor(avgScore);
                      final String scoreLabel = avgScore >= 80
                          ? 'PROTECTED'
                          : avgScore >= 50
                              ? 'CAUTION'
                              : 'AT RISK';
                      final String deviceLabel = avgScore >= 80
                          ? 'Your device\nis safe'
                          : avgScore >= 50
                              ? 'Some risks\ndetected'
                              : 'Threats\ndetected';

                      return Column(
                        children: [
                          // การ์ดวงแหวนความปลอดภัย
                          _buildSecurityCard(
                            scoreRatio:  scoreRatio,
                            scoreColor:  scoreColor,
                            scoreLabel:  scoreLabel,
                            deviceLabel: deviceLabel,
                            avgScore:    avgScore,
                          ),
                          const SizedBox(height: 20),

                          // Stat cards — real data
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  totalScans.toString(),
                                  'SCANNED',
                                  Icons.shield_outlined,
                                  null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  threatCount.toString(),
                                  'THREATS',
                                  Icons.warning_amber_rounded,
                                  Colors.yellow,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  safeCount.toString(),
                                  'SAFE',
                                  Icons.check_circle_outline,
                                  const Color(0xFF00FFB2),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

            const SizedBox(height: 20),
            _buildUpdateBanner(),
            const SizedBox(height: 30),

            // ── Recent scans — real data from Firestore ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Scans',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                TextButton(
                  onPressed: widget.onSeeAll,
                  child: const Text(
                    'See all',
                    style: TextStyle(
                        color: Color(0xFF00FFB2),
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            user == null
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Log in to see recent scans',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('scanHistory')
                        .orderBy('scannedAt', descending: true)
                        .limit(4) // แสดงเฉพาะ 4 รายการล่าสุดบนแดชบอร์ด
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF00FFB2)),
                        );
                      }

                      final docs = snap.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161B22),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Text(
                              'No scans yet — tap Quick Scan to start.',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: docs.map((doc) {
                          final data = doc.data()
                              as Map<String, dynamic>;
                          return _buildScanItem(data);
                        }).toList(),
                      );
                    },
                  ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Security ring card (real data) ──
  Widget _buildSecurityCard({
    required double scoreRatio,
    required Color scoreColor,
    required String scoreLabel,
    required String deviceLabel,
    required int avgScore,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF131F1D),
        borderRadius: BorderRadius.circular(32),
        border:
            Border.all(color: scoreColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: scoreRatio,
                  strokeWidth: 8,
                  backgroundColor:
                      Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      scoreColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$avgScore%',
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const Text(
                    'WEEKLY',
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold),
                  ),
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
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: scoreColor,
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      scoreLabel,
                      style: TextStyle(
                          color: scoreColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  deviceLabel,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      color: Colors.white),
                ),
                const SizedBox(height: 8),
                const QuotaStatusWidget(type: 'text'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _handleQuickScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Quick Scan',
                          style: TextStyle(
                              fontWeight: FontWeight.bold)),
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

  // ── Guest security card (no data) ──
  Widget _buildGuestSecurityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF131F1D),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
            color: const Color(0xFF00FFB2).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: 0,
                  strokeWidth: 8,
                  backgroundColor:
                      Colors.white.withOpacity(0.1),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(
                          Colors.grey),
                ),
              ),
              const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '--',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  Text(
                    'WEEKLY',
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Log in to see your\nsecurity score',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      color: Colors.white),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _handleQuickScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Quick Scan',
                          style: TextStyle(
                              fontWeight: FontWeight.bold)),
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
        border: Border.all(
            color: const Color(0xFFFF4B6C).withOpacity(0.3),
            width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: Color(0xFFFF4B6C),
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'SYSTEM SETTINGS',
                      style: TextStyle(
                          color: Color(0xFFFF4B6C),
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Check OS security in settings',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => AppSettings.openAppSettings(
                type: AppSettingsType.security),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B6C),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Open',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String val, String label, IconData icon, Color? iconColor) {
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
          Text(
            val,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ── Recent scan item (real data) ──
  Widget _buildScanItem(Map<String, dynamic> data) {
    final String fileName = data['fileName'] ?? 'Unknown';
    final String fileSize = data['fileSize'] ?? '';
    final int    score    = data['score']    ?? 0;
    final String status   = data['status']   ?? 'Unknown';
    final String fileType = data['fileType'] ?? '';
    final Timestamp? scannedAt = data['scannedAt'] as Timestamp?;

    final color    = _scoreColor(score);
    final timeStr  = _formatTime(scannedAt);
    final infoText = '$fileSize · $timeStr';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2524),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_fileIcon(fileType),
                color: Colors.grey[400]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  infoText,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
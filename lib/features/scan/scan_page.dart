import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/widgets/custom_header.dart';
import '../../core/widgets/quota_status_widget.dart';
import '../../core/services/scan_limit_service.dart';
import '../../core/routes/app_routes.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _isDeepScan = false;
  bool _showApiKeyWarning = false;
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _launchVirusTotalUrl() async {
    final Uri url = Uri.parse('https://www.virustotal.com/gui/my-apikey');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _handleFileSelection() async {
    // ── ขั้นตอนที่ 1: ตรวจสอบ API key เมื่อเปิดโหมด Deep Scan ──
    if (_isDeepScan && _apiKeyController.text.trim().isEmpty) {
      setState(() => _showApiKeyWarning = true);
      return;
    }

    // ── ขั้นตอนที่ 2: ตรวจสอบโควตาการสแกน ──
    bool canScan = await ScanLimitService.canScan();
    if (!canScan) {
      _showUpgradeDialog(
        'Limit Reached',
        'You have used all free scans for today.',
      );
      return;
    }

    // ── ขั้นตอนที่ 3: เลือกไฟล์ ──
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: false,
      withReadStream: false,
    );

    if (result != null) {
      PlatformFile file = result.files.first;

      if (file.path == null) {
        _showErrorSnackbar('Could not access file. Please try again.');
        return;
      }

      // ── ขั้นตอนที่ 4: เพิ่มจำนวนการสแกนที่ใช้ไป ──
      await ScanLimitService.incrementScan();
      ScanLimitService.notifyRefresh();

      // ── ขั้นตอนที่ 5: ไปหน้ารายละเอียดทันทีพร้อมข้อมูลไฟล์ ──
      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.scanResult,
          arguments: {
            'fileName': file.name,
            'fileSize': '${(file.size / 1024).toStringAsFixed(2)} KB',
            'filePath': file.path,
            'isDeepScan': _isDeepScan,
            'apiKey': _apiKeyController.text.trim(),
          },
        );
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF4B6C),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showUpgradeDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(Icons.star, color: Color(0xFF00FFB2)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          content,
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'LATER',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.subscription);
            },
            child: const Text(
              'UPGRADE',
              style: TextStyle(
                color: Color(0xFF00FFB2),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: StreamBuilder<DocumentSnapshot>(
        stream: user != null
            ? FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots()
            : null,
        builder: (context, snapshot) {
          bool isPro = false;
          if (snapshot.hasData && snapshot.data!.exists) {
            isPro = (snapshot.data!.data()
                as Map<String, dynamic>)['isPro'] ?? false;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            child: Column(
              children: [
                const CustomHeader(),
                const SizedBox(height: 30),
                const QuotaStatusWidget(type: 'bar'),
                const SizedBox(height: 32),

                // ── หัวเรื่อง ──
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(text: 'File '),
                      TextSpan(
                        text: 'Scanner',
                        style: TextStyle(color: Color(0xFF00FFB2)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Upload a file to verify its safety.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 30),

                // ── พื้นที่อัปโหลดไฟล์ ──
                GestureDetector(
                  onTap: _handleFileSelection,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF00FFB2).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.drive_folder_upload_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tap to select file',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        // แสดงโหมดสแกนปัจจุบัน
                        Text(
                          _isDeepScan
                              ? '🔍 Deep Scan mode'
                              : '⚡ Basic Scan mode',
                          style: TextStyle(
                            color: _isDeepScan
                                ? const Color(0xFF00FFB2)
                                : Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── ปุ่มเลือกไฟล์ ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleFileSelection,
                    icon: const Icon(
                      Icons.file_present,
                      color: Colors.black,
                    ),
                    label: const Text(
                      'SELECT FILE',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FFB2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── สวิตช์ Deep Scan ──
                GestureDetector(
                  onTap: isPro
                      ? null
                      : () => _showUpgradeDialog(
                            'PRO Feature',
                            'Deep Scan is only available for PRO members. Upgrade now to unlock!',
                          ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.security,
                        color: isPro
                            ? const Color(0xFF00FFB2)
                            : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Deep Scan',
                        style: TextStyle(
                          fontSize: 16,
                          color: isPro ? Colors.white : Colors.grey,
                        ),
                      ),
                      if (!isPro) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.lock,
                          color: Colors.amber,
                          size: 14,
                        ),
                      ],
                      const SizedBox(width: 12),
                      Switch(
                        value: isPro ? _isDeepScan : false,
                        activeColor: const Color(0xFF00FFB2),
                        onChanged: isPro
                            ? (val) => setState(() {
                                  _isDeepScan = val;
                                  // ล้างข้อความเตือนเมื่อปิด
                                  if (!val) _showApiKeyWarning = false;
                                })
                            : null,
                      ),
                    ],
                  ),
                ),

                // ── ส่วน API Key (แสดงเมื่อเปิด Deep Scan) ──
                if (_isDeepScan && isPro) ...[
                  const SizedBox(height: 24),

                  // ── แบนเนอร์เตือน ──
                  if (_showApiKeyWarning) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4B6C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF4B6C).withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFFF4B6C),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Please enter your VirusTotal API key or turn off Deep Scan to continue.',
                              style: TextStyle(
                                color: Color(0xFFFF4B6C),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                          // การกระทำด่วน — ปิด Deep Scan
                          GestureDetector(
                            onTap: () => setState(() {
                              _isDeepScan = false;
                              _showApiKeyWarning = false;
                            }),
                            child: const Text(
                              'Turn off',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── ป้าย API Key ──
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'VirusTotal API Key',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── ช่องกรอก API Key ──
                  TextField(
                    controller: _apiKeyController,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (_) {
                      // ล้างข้อความเตือนเมื่อผู้ใช้พิมพ์
                      if (_showApiKeyWarning) {
                        setState(() => _showApiKeyWarning = false);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter your API Key',
                      hintStyle: TextStyle(color: Colors.grey[700]),
                      prefixIcon: const Icon(
                        Icons.key,
                        color: Colors.grey,
                      ),
                      // ขอบแดงเมื่อมีเตือน
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _showApiKeyWarning
                              ? const Color(0xFFFF4B6C)
                              : Colors.transparent,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF00FFB2),
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF161B22),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── ลิงก์วิธีขอ API key ──
                  GestureDetector(
                    onTap: _launchVirusTotalUrl,
                    child: const Text(
                      'How to get VirusTotal API Key?',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        decoration: TextDecoration.underline,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
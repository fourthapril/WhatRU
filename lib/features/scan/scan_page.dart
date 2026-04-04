import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // สำหรับเปิดลิงก์ภายนอก
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
  bool _isScanning = false;
  final TextEditingController _apiKeyController = TextEditingController();

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  // ฟังก์ชันสำหรับเปิดหน้าเว็บเพื่อขอ API Key
  Future<void> _launchVirusTotalUrl() async {
    final Uri url = Uri.parse('https://www.virustotal.com/gui/my-apikey');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _handleFileSelection() async {
    bool canScan = await ScanLimitService.canScan();
    if (!canScan) {
      _showUpgradeDialog("Limit Reached", "You have used all free scans for today.");
      return;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      PlatformFile file = result.files.first;
      setState(() => _isScanning = true);

      await ScanLimitService.incrementScan();
      ScanLimitService.notifyRefresh(); 

      await Future.delayed(const Duration(milliseconds: 1200));

      if (mounted) {
        setState(() => _isScanning = false);
        Navigator.pushNamed(
          context, 
          '/scan_result', 
          arguments: {
            'fileName': file.name,
            'fileSize': '${(file.size / 1024).toStringAsFixed(2)} KB',
            'filePath': file.path,
            'isDeepScan': _isDeepScan,
            'apiKey': _apiKeyController.text, // ส่งค่า API Key ไปยังหน้าถัดไป
          },
        );
      }
    }
  }

  void _showUpgradeDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.star, color: Color(0xFF00FFB2)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Text(content, style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('LATER', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.subscription);
            },
            child: const Text('UPGRADE', style: TextStyle(color: Color(0xFF00FFB2), fontWeight: FontWeight.bold)),
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
        // ดึงข้อมูลผู้ใช้แบบ Real-time เพื่อตรวจสอบสถานะ PRO
        stream: user != null 
            ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
            : null,
        builder: (context, snapshot) {
          bool isPro = false;
          if (snapshot.hasData && snapshot.data!.exists) {
            isPro = (snapshot.data!.data() as Map<String, dynamic>)['isPro'] ?? false;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                const CustomHeader(),
                const SizedBox(height: 30),
                const QuotaStatusWidget(type: 'bar'),
                const SizedBox(height: 32),

                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    children: [
                      TextSpan(text: 'File '),
                      TextSpan(text: 'Scanner', style: TextStyle(color: Color(0xFF00FFB2))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Please upload a file to verify its safety.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 30),
                
                // พื้นที่สำหรับอัปโหลดไฟล์
                GestureDetector(
                  onTap: _isScanning ? null : _handleFileSelection,
                  child: Container(
                    width: double.infinity, height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _isScanning ? const Color(0xFF00FFB2) : const Color(0xFF00FFB2).withOpacity(0.3), width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _isScanning ? const CircularProgressIndicator(color: Color(0xFF00FFB2)) : const Icon(Icons.drive_folder_upload_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(_isScanning ? 'Analyzing...' : 'Tap to select file', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // ปุ่มเลือกไฟล์
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? null : _handleFileSelection,
                    icon: const Icon(Icons.file_present, color: Colors.black),
                    label: const Text('SELECT FILE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FFB2), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  ),
                ),
                const SizedBox(height: 20),

                // ตัวเลือกสแกนแบบเจาะลึก (Deep Scan) สงวนสิทธิ์เฉพาะผู้ใช้ PRO
                GestureDetector(
                  onTap: isPro ? null : () => _showUpgradeDialog("PRO Feature", "Deep Scan is only available for PRO members. Upgrade now to unlock!"),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.security, color: isPro ? const Color(0xFF00FFB2) : Colors.grey, size: 18),
                      const SizedBox(width: 8),
                      Text('Deep Scan', style: TextStyle(fontSize: 16, color: isPro ? Colors.white : Colors.grey)),
                      if (!isPro) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.lock, color: Colors.amber, size: 14),
                      ],
                      const SizedBox(width: 12),
                      Switch(
                        value: isPro ? _isDeepScan : false,
                        activeColor: const Color(0xFF00FFB2),
                        onChanged: isPro ? (val) => setState(() => _isDeepScan = val) : null,
                      ),
                    ],
                  ),
                ),

                // แสดงช่องกรอก API Key เฉพาะเมื่อเปิดใช้งาน Deep Scan
                if (_isDeepScan && isPro) ...[
                  const SizedBox(height: 30),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('VirusTotal API Key', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _apiKeyController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter API Key',
                      hintStyle: TextStyle(color: Colors.grey[700]),
                      prefixIcon: const Icon(Icons.key, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF161B22),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _launchVirusTotalUrl, // เปิดหน้าเว็บเพื่อรับ API Key
                    child: const Text(
                      'How to get VirusTotal API Key?',
                      style: TextStyle(color: Color(0xFF00E5FF), decoration: TextDecoration.underline, fontSize: 12),
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
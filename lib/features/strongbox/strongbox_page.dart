import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/widgets/custom_header.dart';
import '../../core/services/weekly_stats_service.dart';

class StrongBoxPage extends StatefulWidget {
  const StrongBoxPage({super.key});

  @override
  State<StrongBoxPage> createState() => _StrongBoxPageState();
}

class _StrongBoxPageState extends State<StrongBoxPage> {

  final Set<String> _loadingDocs = {};

  // สร้าง SHA-256 hash ของไฟล์จากไฟล์ในเครื่อง
  String? _generateHash(String filePath) {
    try {
      final bytes = File(filePath).readAsBytesSync();
      return sha256.convert(bytes).toString();
    } catch (_) {
      return null;
    }
  }

  // เลือกสีตาม score เพื่อแสดงสถานะความปลอดภัย
  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF00FFB2);
    if (score >= 50) return Colors.amber;
    return const Color(0xFFFF4B6C);
  }

  // คืน Icon ตามนามสกุลไฟล์
  IconData _fileIcon(String fileName) {
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    switch (ext) {
      case 'pdf':  return Icons.picture_as_pdf;
      case 'exe':
      case 'dll':  return Icons.terminal;
      case 'zip':
      case 'rar':
      case '7z':   return Icons.folder_zip;
      case 'doc':
      case 'docx': return Icons.description;
      case 'xls':
      case 'xlsx': return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':  return Icons.image;
      case 'mp4':  return Icons.movie;
      default:     return Icons.insert_drive_file_outlined;
    }
  }

  // แปลง Timestamp เป็นวันที่แบบอ่านง่าย
  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Never';
    final d = timestamp.toDate();
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  // ─────────────────────────────────────────────
  // ย้ายตำแหน่งไฟล์ — อัปเดตเฉพาะ filePath เท่านั้น ไม่รีเซ็ต hash
  // ─────────────────────────────────────────────
  Future<void> _handleRelocate(
    String docId,
    String uid,
    String fileName,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      withData: false,
      withReadStream: false,
    );

    if (result == null) return;
    final file = result.files.first;
    if (file.path == null) return;

    setState(() => _loadingDocs.add(docId));

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('strongBox')
          .doc(docId)
          .update({'filePath': file.path});

      _showSnackbar('File location updated successfully.');
    } catch (e) {
      _showSnackbar('Relocate failed: $e', isError: true);
    } finally {
      setState(() => _loadingDocs.remove(docId));
    }
  }

  // ─────────────────────────────────────────────
  // ยืนยัน hash อีกครั้ง
  // ถ้า hash เปลี่ยน:
  //   → อัปเดต score ใน StrongBox
  //   → อัปเดต matching history score
  //   → คำนวณ weekly stats ใหม่
  //   → เขียน in-app notification
  // ถ้า hash เหมือนเดิม:
  //   → เขียน in-app notification ว่า verified OK
  // ─────────────────────────────────────────────
  Future<void> _handleReVerify(
    String docId,
    String uid,
    String filePath,
    String savedHash,
    String fileName,
    int currentScore,
  ) async {
    setState(() => _loadingDocs.add(docId));

    try {
      if (filePath.isEmpty || !File(filePath).existsSync()) {
        _showFileNotFoundDialog(fileName);
        return;
      }

      final currentHash = _generateHash(filePath);
      if (currentHash == null) {
        _showSnackbar('Could not read file.', isError: true);
        return;
      }

      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(uid);

      if (currentHash == savedHash) {
        // ── Hash ไม่เปลี่ยน ──
        await userDoc
            .collection('strongBox')
            .doc(docId)
            .update({
          'lastVerified': FieldValue.serverTimestamp(),
          'hashChanged':  false,
        });

        // สร้าง notification ในแอป — ไฟล์ยังปกติ
        await userDoc.collection('notifications').add({
          'title':     '✅ File Integrity Verified',
          'message':   '$fileName is unchanged. Hash matches original.',
          'type':      'scan',
          'isRead':    false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        _showSnackbar(
            '$fileName is unchanged. File integrity verified ✓');
      } else {
        // ── Hash เปลี่ยน ──
        final newScore  = (currentScore - 30).clamp(0, 100);
        final newStatus = newScore >= 80
            ? 'Safe'
            : newScore >= 50
                ? 'Warning'
                : 'Threat';

        // อัปเดต StrongBox
        await userDoc
            .collection('strongBox')
            .doc(docId)
            .update({
          'fileHash':     currentHash,
          'score':        newScore,
          'status':       newStatus,
          'lastVerified': FieldValue.serverTimestamp(),
          'hashChanged':  true,
        });

        // ── หาและอัปเดต history entry ที่ตรงกัน ──
        final historySnap = await userDoc
            .collection('scanHistory')
            .where('fileName', isEqualTo: fileName)
            .where('fileHash', isEqualTo: savedHash)
            .limit(1)
            .get();

        if (historySnap.docs.isNotEmpty) {
          final historyDoc  = historySnap.docs.first;
          final historyData = historyDoc.data();

          // หาสัปดาห์ของการสแกนนี้
          final Timestamp? scannedAt =
              historyData['scannedAt'] as Timestamp?;
          final weekId =
              WeeklyStatsService.weekIdFromTimestamp(
                  scannedAt);

          // อัปเดต score ใน history
          await historyDoc.reference.update({
            'score':  newScore,
            'status': newStatus,
          });

          // คำนวณ average ของสัปดาห์นั้นใหม่
          await WeeklyStatsService.recalculate(
              uid, weekId);
        }

        // สร้าง notification ในแอป — ไฟล์ถูกแก้ไข
        await userDoc.collection('notifications').add({
          'title':   '⚠️ File Modification Detected!',
          'message': '$fileName SHA-256 hash changed. Score: $currentScore → $newScore.',
          'type':    'threat',
          'isRead':  false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        _showHashChangedDialog(fileName, currentScore, newScore);
      }
    } catch (e) {
      _showSnackbar('Re-verify failed: $e', isError: true);
    } finally {
      setState(() => _loadingDocs.remove(docId));
    }
  }

  // ─────────────────────────────────────────────
  // ลบจาก StrongBox
  // ลบเฉพาะ record ใน StrongBox เท่านั้น
  // ประวัติ scan และ weekly stats จะไม่ถูกกระทบ
  // ─────────────────────────────────────────────
  Future<void> _handleDelete(
    String docId,
    String uid,
    String fileName,
  ) async {
    final confirmed = await _showDeleteConfirmDialog(fileName);
    if (!confirmed) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('strongBox')
          .doc(docId)
          .delete();

      _showSnackbar('$fileName removed from StrongBox.');
    } catch (e) {
      _showSnackbar('Failed to remove: $e', isError: true);
    }
  }

  Future<bool> _showDeleteConfirmDialog(String fileName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline,
                color: Color(0xFFFF4B6C)),
            SizedBox(width: 8),
            Text('Remove File',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Remove $fileName from StrongBox?\n\nThis will not delete the file itself or its scan history.',
          style: const TextStyle(
              color: Colors.grey, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL',
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('REMOVE',
                style: TextStyle(
                    color: Color(0xFFFF4B6C),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showFileNotFoundDialog(String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.search_off, color: Colors.grey),
            SizedBox(width: 8),
            Text('File Not Found',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          '$fileName could not be found at its saved location.\n\nThis usually happens after changing phones or moving the file.\n\nUse "Relocate" to point to the new file location.',
          style: const TextStyle(
              color: Colors.grey, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK',
                style: TextStyle(
                    color: Color(0xFF00FFB2),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showHashChangedDialog(
      String fileName, int oldScore, int newScore) {
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
            Text('File Modified!',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          '$fileName has been modified since it was last saved.\n\nThe SHA-256 hash no longer matches the original.\n\nScore reduced: $oldScore → $newScore.\nScan history and weekly average updated.',
          style: const TextStyle(
              color: Colors.grey, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK',
                style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFFF4B6C)
            : const Color(0xFF00FFB2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
            child: CustomHeader(),
          ),

          if (user == null)
            Expanded(child: _buildGuestState())
          else
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('strongBox')
                    .orderBy('savedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF00FFB2)),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  int safeCount  = 0;
                  int alertCount = 0;
                  for (final doc in docs) {
                    final data =
                        doc.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'Safe';
                    if (status == 'Threat' ||
                        (data['hashChanged'] ?? false)) {
                      alertCount++;
                    } else {
                      safeCount++;
                    }
                  }

                  return Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131F1D),
                          borderRadius:
                              BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00FFB2)
                                    .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                  Icons.lock_outline,
                                  color: Color(0xFF00FFB2),
                                  size: 30),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('My StrongBox',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight.bold,
                                          color:
                                              Colors.white)),
                                  Text(
                                      'Keep your files safe',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey)),
                                ],
                              ),
                            ),
                            _buildBadge(
                                safeCount.toString(),
                                const Color(0xFF00FFB2)),
                            const SizedBox(width: 8),
                            _buildBadge(
                                alertCount.toString(),
                                const Color(0xFFFF4B6C)),
                          ],
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20),
                        child: Text(
                          'Stored Files',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Expanded(
                        child: docs.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 20),
                                itemCount: docs.length + 1,
                                itemBuilder:
                                    (context, index) {
                                  if (index == docs.length) {
                                    return const SizedBox(
                                        height: 80);
                                  }
                                  final doc = docs[index];
                                  final data = doc.data()
                                      as Map<String, dynamic>;
                                  return _buildStoredFile(
                                    docId: doc.id,
                                    uid:   user.uid,
                                    data:  data,
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStoredFile({
    required String docId,
    required String uid,
    required Map<String, dynamic> data,
  }) {
    final String fileName    = data['fileName']    ?? 'Unknown';
    final String fileSize    = data['fileSize']    ?? '';
    final String filePath    = data['filePath']    ?? '';
    final String savedHash   = data['fileHash']    ?? '';
    final int    score       = data['score']       ?? 0;
    final String status      = data['status']      ?? 'Safe';
    final bool   hashChanged = data['hashChanged'] ?? false;
    final Timestamp? savedAt      = data['savedAt']      as Timestamp?;
    final Timestamp? lastVerified = data['lastVerified'] as Timestamp?;

    final bool  isAlert  = status == 'Threat' || hashChanged;
    final Color color    = hashChanged
        ? const Color(0xFFFF4B6C)
        : _scoreColor(score);
    final bool  isLoading = _loadingDocs.contains(docId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(20),
        border: isAlert
            ? Border.all(color: color.withOpacity(0.3))
            : Border.all(
                color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_fileIcon(fileName), color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(fileSize,
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11)),
                  ],
                ),
              ),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAlert
                          ? Icons.warning
                          : Icons.check_circle,
                      color: color,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isAlert ? 'ALERT' : 'SECURE',
                      style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ── X delete button ──
              GestureDetector(
                onTap: () =>
                    _handleDelete(docId, uid, fileName),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.close,
                      size: 14, color: Colors.grey),
                ),
              ),
            ],
          ),

          if (hashChanged) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4B6C)
                    .withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFF4B6C)
                        .withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFFF4B6C), size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'File has been modified since last save. Score: $score/100.',
                      style: const TextStyle(
                          color: Color(0xFFFF4B6C),
                          fontSize: 11,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$score/100',
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Saved ${_formatDate(savedAt)}  ·  Verified ${_formatDate(lastVerified)}',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => _handleRelocate(
                        docId, uid, fileName),
                icon: const Icon(
                    Icons.folder_copy_outlined,
                    size: 14,
                    color: Colors.grey),
                label: const Text('Relocate',
                    style: TextStyle(
                        color: Colors.grey, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: Colors.grey, width: 0.5),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),

              OutlinedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => _handleReVerify(
                          docId,
                          uid,
                          filePath,
                          savedHash,
                          fileName,
                          score,
                        ),
                icon: isLoading
                    ? SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            color: color, strokeWidth: 2),
                      )
                    : Icon(Icons.refresh,
                        size: 14, color: color),
                label: Text(
                  isLoading ? 'Checking...' : 'Re-verify',
                  style:
                      TextStyle(color: color, fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: color.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18)),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_open_outlined,
              color: Colors.grey, size: 48),
          SizedBox(height: 16),
          Text('StrongBox is empty',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          SizedBox(height: 8),
          Text(
            'Save a scanned file to monitor\nits integrity over time.',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline,
              color: Colors.grey, size: 48),
          SizedBox(height: 16),
          Text('Log in to use StrongBox',
              style:
                  TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }
}
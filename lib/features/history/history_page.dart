import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/widgets/custom_header.dart';
import '../../core/services/weekly_stats_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {

  String _selectedSort   = 'Newest';
  String _selectedStatus = 'All';

  // แปลง Timestamp เป็นข้อความวันที่แบบอ่านง่าย
  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final d = timestamp.toDate();
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final hour   = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year}, $hour:$minute';
  }

  // เลือกสีตาม score เพื่อแสดงสถานะความปลอดภัย
  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF00FFB2);
    if (score >= 50) return Colors.amber;
    return const Color(0xFFFF4B6C);
  }

  // คืน Icon ตามประเภทไฟล์ (fileType)
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

  // กรองประวัติการสแกนตาม status และเรียงตาม selected sort
  List<QueryDocumentSnapshot> _applyFilter(
      List<QueryDocumentSnapshot> docs) {
    var filtered = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      if (_selectedStatus == 'All') return true;
      return (data['status'] ?? '') == _selectedStatus;
    }).toList();

    filtered.sort((a, b) {
      final da = a.data() as Map<String, dynamic>;
      final db = b.data() as Map<String, dynamic>;
      switch (_selectedSort) {
        case 'Newest':
          final ta = (da['scannedAt'] as Timestamp?)
                  ?.toDate() ??
              DateTime(0);
          final tb = (db['scannedAt'] as Timestamp?)
                  ?.toDate() ??
              DateTime(0);
          return tb.compareTo(ta);
        case 'Oldest':
          final ta = (da['scannedAt'] as Timestamp?)
                  ?.toDate() ??
              DateTime(0);
          final tb = (db['scannedAt'] as Timestamp?)
                  ?.toDate() ??
              DateTime(0);
          return ta.compareTo(tb);
        case 'Largest':
          final sa = double.tryParse((da['fileSize'] ?? '0')
                  .toString()
                  .split(' ')
                  .first) ??
              0;
          final sb = double.tryParse((db['fileSize'] ?? '0')
                  .toString()
                  .split(' ')
                  .first) ??
              0;
          return sb.compareTo(sa);
        case 'Smallest':
          final sa = double.tryParse((da['fileSize'] ?? '0')
                  .toString()
                  .split(' ')
                  .first) ??
              0;
          final sb = double.tryParse((db['fileSize'] ?? '0')
                  .toString()
                  .split(' ')
                  .first) ??
              0;
          return sa.compareTo(sb);
        default:
          return 0;
      }
    });

    return filtered;
  }

  // ─────────────────────────────────────────────
  // ลบประวัติการสแกน
  // 1. ลบ document ใน scanHistory
  // 2. คำนวณ weeklyStats ใหม่สำหรับสัปดาห์นั้น
  // ค่าเฉลี่ย dashboard จะอัปเดตเองผ่าน StreamBuilder
  // ─────────────────────────────────────────────
  Future<void> _handleDelete(
    String docId,
    String uid,
    String fileName,
    Timestamp? scannedAt,
  ) async {
    final confirmed = await _showDeleteConfirmDialog(fileName);
    if (!confirmed) return;

    try {
      // เตรียม weekId ก่อนลบ
      final weekId =
          WeeklyStatsService.weekIdFromTimestamp(scannedAt);

      // ลบจาก scanHistory
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('scanHistory')
          .doc(docId)
          .delete();

      // คำนวณ weekly stats ใหม่สำหรับสัปดาห์ที่เกี่ยวข้อง
      // ซึ่งจะอัปเดต dashboard average โดยอัตโนมัติ
      await WeeklyStatsService.recalculate(uid, weekId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$fileName removed from history.'),
            backgroundColor: const Color(0xFF00FFB2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: const Color(0xFFFF4B6C),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // แสดง dialog สำหรับยืนยันการลบประวัติการสแกน
  Future<bool> _showDeleteConfirmDialog(
      String fileName) async {
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
            Text('Delete Scan',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Delete $fileName from history?\n\nThis will also update your weekly security average.',
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
            child: const Text('DELETE',
                style: TextStyle(
                    color: Color(0xFFFF4B6C),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding:
                EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: CustomHeader(),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text('History',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                ElevatedButton.icon(
                  onPressed: () =>
                      _showFilterBottomSheet(context),
                  icon: const Icon(Icons.filter_list,
                      size: 16,
                      color: Color(0xFF00FFB2)),
                  label: const Text('Filter',
                      style: TextStyle(
                          color: Color(0xFF00FFB2))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FFB2)
                        .withOpacity(0.1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: user == null
                ? _buildGuestState()
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('scanHistory')
                        .orderBy('scannedAt',
                            descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF00FFB2)),
                        );
                      }
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                              'Error loading history.',
                              style: TextStyle(
                                  color: Colors.grey)),
                        );
                      }

                      final allDocs =
                          snapshot.data?.docs ?? [];

                      if (allDocs.isEmpty) {
                        return _buildEmptyState();
                      }

                      final filtered =
                          _applyFilter(allDocs);

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text(
                            'No files match your filter.',
                            style: TextStyle(
                                color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20),
                        itemCount: filtered.length + 1,
                        itemBuilder: (context, index) {
                          if (index == filtered.length) {
                            return const SizedBox(
                                height: 80);
                          }
                          final doc    = filtered[index];
                          final data   = doc.data()
                              as Map<String, dynamic>;
                          return _buildHistoryItem(
                            docId: doc.id,
                            uid:   user.uid,
                            data:  data,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required String docId,
    required String uid,
    required Map<String, dynamic> data,
  }) {
    final String fileName   = data['fileName']   ?? 'Unknown File';
    final String fileSize   = data['fileSize']   ?? '';
    final int    score      = data['score']      ?? 0;
    final String status     = data['status']     ?? 'Unknown';
    final String fileType   = data['fileType']   ?? '';
    final bool   isDeepScan = data['isDeepScan'] ?? false;
    final Timestamp? scannedAt = data['scannedAt'] as Timestamp?;

    final color    = _scoreColor(score);
    final subtitle =
        '${_formatDateTime(scannedAt)}  ·  $fileSize';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // File icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_fileIcon(fileType), color: color),
          ),
          const SizedBox(width: 16),

          // File name + info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11)),
                if (isDeepScan) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FFB2)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'DEEP SCAN',
                      style: TextStyle(
                          color: Color(0xFF00FFB2),
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Score + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(score.toString(),
                  style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              Text(status.toUpperCase(),
                  style: TextStyle(
                      color: color.withOpacity(0.8),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5)),
            ],
          ),

          const SizedBox(width: 8),

          // ── X delete button ──
          GestureDetector(
            onTap: () => _handleDelete(
                docId, uid, fileName, scannedAt),
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
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, color: Colors.grey, size: 48),
          SizedBox(height: 16),
          Text('No scans yet',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          SizedBox(height: 8),
          Text('Scan a file to see your history here.',
              style: TextStyle(
                  color: Colors.grey, fontSize: 13)),
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
          Text('Log in to see your history',
              style:
                  TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131F1D),
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder:
              (BuildContext context, StateSetter setModalState) {
            return SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.only(
                  top: 24,
                  left: 24,
                  right: 24,
                  bottom:
                      24 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius:
                              BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Sort & Filter',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 24),
                    const Text('Sort By',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildChip('Newest',   _selectedSort,   (v) => setModalState(() => _selectedSort   = v)),
                        _buildChip('Oldest',   _selectedSort,   (v) => setModalState(() => _selectedSort   = v)),
                        _buildChip('Largest',  _selectedSort,   (v) => setModalState(() => _selectedSort   = v)),
                        _buildChip('Smallest', _selectedSort,   (v) => setModalState(() => _selectedSort   = v)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Filter By Status',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildChip('All',     _selectedStatus, (v) => setModalState(() => _selectedStatus = v)),
                        _buildChip('Safe',    _selectedStatus, (v) => setModalState(() => _selectedStatus = v), activeColor: const Color(0xFF00FFB2)),
                        _buildChip('Warning', _selectedStatus, (v) => setModalState(() => _selectedStatus = v), activeColor: Colors.amber),
                        _buildChip('Threat',  _selectedStatus, (v) => setModalState(() => _selectedStatus = v), activeColor: const Color(0xFFFF4B6C)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF00FFB2),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16)),
                        ),
                        child: const Text('Apply Filters',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChip(
    String label,
    String selectedValue,
    Function(String) onSelected, {
    Color? activeColor,
  }) {
    final bool  isSelected = label == selectedValue;
    final Color color = activeColor ?? const Color(0xFF00FFB2);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) onSelected(label);
      },
      selectedColor: color.withOpacity(0.2),
      backgroundColor: const Color(0xFF161B22),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey,
        fontWeight: isSelected
            ? FontWeight.bold
            : FontWeight.normal,
      ),
      side: BorderSide(
          color: isSelected ? color : Colors.transparent),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    );
  }
}
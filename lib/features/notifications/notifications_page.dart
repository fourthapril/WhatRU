import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  // ── แปลง timestamp เป็นเวลาสัมพัทธ์ ──
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

  // ── จัดกลุ่มการแจ้งเตือนตามป้ายวันที่ ──
  String _dateLabel(Timestamp? timestamp) {
    if (timestamp == null) return 'Earlier';
    final now = DateTime.now();
    final time = timestamp.toDate();
    final diff = now.difference(time);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays <= 7) return 'This Week';
    return 'Earlier';
  }

  // ── แปลงประเภทการแจ้งเตือนเป็นไอคอนและสี ──
  IconData _getIcon(String type) {
    switch (type) {
      case 'threat':  return Icons.warning_amber_rounded;
      case 'warning': return Icons.error_outline;
      case 'scan':    return Icons.check_circle_outline;
      default:        return Icons.notifications_outlined;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'threat':  return const Color(0xFFFF4B6C);
      case 'warning': return Colors.amber;
      case 'scan':    return const Color(0xFF00FFB2);
      default:        return Colors.blue;
    }
  }

  // ── ทำเครื่องหมายทุกการแจ้งเตือนว่าอ่านแล้ว ──
  Future<void> _markAllRead(String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    final unread = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E11),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
        actions: [
          // ปุ่มทำเครื่องหมายทั้งหมดว่าอ่านแล้ว — แสดงเฉพาะเมื่อเข้าสู่ระบบ
          if (user != null)
            TextButton(
              onPressed: () => _markAllRead(user.uid),
              child: const Text(
                'Mark read',
                style: TextStyle(
                    color: Color(0xFF00FFB2),
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: user == null
          ? _buildGuestState()
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('notifications')
                  .orderBy('createdAt', descending: true)
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

                if (docs.isEmpty) {
                  return _buildEmptyState();
                }

                // จัดกลุ่มเอกสารตามป้ายวันที่
                final Map<String, List<QueryDocumentSnapshot>>
                    grouped = {};
                for (final doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final label = _dateLabel(
                      data['createdAt'] as Timestamp?);
                  grouped.putIfAbsent(label, () => []).add(doc);
                }

                // สร้างรายการพร้อมหัวเรื่องแต่ละส่วน
                final List<Widget> items = [];
                const sectionOrder = [
                  'Today', 'Yesterday', 'This Week', 'Earlier'
                ];

                for (final section in sectionOrder) {
                  if (!grouped.containsKey(section)) continue;
                  // หัวข้อส่วน
                  items.add(
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: 12, top: 4),
                      child: Text(
                        section,
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                  // ไอเท็มการแจ้งเตือน
                  for (final doc in grouped[section]!) {
                    final data =
                        doc.data() as Map<String, dynamic>;
                    items.add(
                      _buildNotificationItem(
                        docId: doc.id,
                        uid: user.uid,
                        title:   data['title']   ?? '',
                        message: data['message'] ?? '',
                        type:    data['type']    ?? 'scan',
                        isUnread: !(data['isRead'] ?? false),
                        timestamp:
                            data['createdAt'] as Timestamp?,
                      ),
                    );
                  }
                  items.add(const SizedBox(height: 8));
                }

                items.add(const SizedBox(height: 80));

                return ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  children: items,
                );
              },
            ),
    );
  }

  // ── รายการการแจ้งเตือนเดียว ──
  Widget _buildNotificationItem({
    required String docId,
    required String uid,
    required String title,
    required String message,
    required String type,
    required bool isUnread,
    required Timestamp? timestamp,
  }) {
    final color   = _getColor(type);
    final icon    = _getIcon(type);
    final timeStr = _formatTime(timestamp);

    return GestureDetector(
      // ทำเครื่องหมายว่าอ่านแล้วเมื่อแตะ
      onTap: () {
        if (isUnread) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('notifications')
              .doc(docId)
              .update({'isRead': true});
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread
              ? const Color(0xFF161B22)
              : const Color(0xFF0B0E11),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnread
                ? color.withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // วงกลมไอคอน
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),

            // หัวเรื่อง + ข้อความ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        height: 1.4),
                  ),
                ],
              ),
            ),

            // จุดสำหรับยังไม่อ่าน
            if (isUnread) ...[
              const SizedBox(width: 12),
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Color(0xFF00FFB2),
                    shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── สถานะว่าง ──
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none,
              color: Colors.grey, size: 48),
          SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Scan a file to receive notifications here.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── สถานะผู้เยี่ยมชม ──
  Widget _buildGuestState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, color: Colors.grey, size: 48),
          SizedBox(height: 16),
          Text(
            'Log in to see notifications',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
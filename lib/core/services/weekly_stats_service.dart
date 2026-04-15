import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────
// WEEKLY STATS SERVICE
// helper ร่วมที่ใช้ทั้ง history_page และ
// strongbox_page เพื่อให้ค่าเฉลี่ยรายสัปดาห์
// ถูกต้องหลังมีการเปลี่ยน score หรือการลบ
// ─────────────────────────────────────────────
class WeeklyStatsService {

  // สร้าง weekId จากวันที่ เช่น "2026-W15"
  static String weekIdFromDate(DateTime date) {
    final firstDay = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(firstDay).inDays;
    final weekNum =
        ((dayOfYear + firstDay.weekday - 1) / 7).ceil();
    return '${date.year}-W$weekNum';
  }

  // สร้าง weekId จาก Firestore Timestamp
  static String weekIdFromTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return weekIdFromDate(DateTime.now());
    return weekIdFromDate(timestamp.toDate());
  }

  // ─────────────────────────────────────────────
  // คำนวณใหม่ทั้งสัปดาห์สำหรับ weekId ที่ระบุ
  // อ่านทุก scan ที่เหลือในสัปดาห์นั้น
  // แล้วเขียนค่า weeklyStats ใหม่ทั้งหมด
  // เรียกใช้หลังลบหรือมีการเปลี่ยน score
  // ─────────────────────────────────────────────
  static Future<void> recalculate(String uid, String weekId) async {
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid);

    // ดึง week document เพื่อหา weekStart/weekEnd
    final weekDoc = await userDoc
        .collection('weeklyStats')
        .doc(weekId)
        .get();

    if (!weekDoc.exists) return;

    final weekData = weekDoc.data()!;
    final Timestamp weekStart = weekData['weekStart'] as Timestamp;
    final Timestamp weekEnd   = weekData['weekEnd']   as Timestamp;

    // Query scanHistory ทั้งหมดในช่วงสัปดาห์นี้
    final scansSnap = await userDoc
        .collection('scanHistory')
        .where('scannedAt', isGreaterThanOrEqualTo: weekStart)
        .where('scannedAt', isLessThan: weekEnd)
        .get();

    final docs = scansSnap.docs;

    if (docs.isEmpty) {
      // ถ้าไม่มี scan ย้อนหลังในสัปดาห์นั้นแล้ว
      // ให้ลบ week document ทิ้ง
      await userDoc.collection('weeklyStats').doc(weekId).delete();
      return;
    }

    // คำนวณค่าสถิติต่างๆ จาก scan ที่เหลือ
    int totalScans   = docs.length;
    int totalScore   = 0;
    int threatCount  = 0;
    int warningCount = 0;
    int safeCount    = 0;

    for (final doc in docs) {
      final data = doc.data();
      final int score    = data['score']  ?? 0;
      final String status = data['status'] ?? 'Safe';
      totalScore += score;
      if (status == 'Threat')       threatCount++;
      else if (status == 'Warning') warningCount++;
      else                          safeCount++;
    }

    final int averageScore = (totalScore / totalScans).round();

    await userDoc.collection('weeklyStats').doc(weekId).update({
      'totalScans':   totalScans,
      'averageScore': averageScore,
      'threatCount':  threatCount,
      'warningCount': warningCount,
      'safeCount':    safeCount,
    });
  }
}

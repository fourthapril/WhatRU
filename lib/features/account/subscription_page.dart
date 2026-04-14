import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// หน้าจอการสมัครสมาชิกสำหรับเลือกแพ็กเกจ WHATRU PRO
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  // สถานะการเลือกแผน: -1 = ยังไม่ระบุ, 0 = รายสัปดาห์, 1 = รายเดือน, 2 = รายปี
  int _selectedPlan = -1;

  // ฟังก์ชันช่วยเหลือสำหรับแสดงการแจ้งเตือนและนำทางกลับ
  void _completeSubscription(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00FFB2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // ล้างประวัติหน้าจอ (Stack) และนำทางกลับไปยังหน้า Account
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.account,
      (route) =>
          route.settings.name == AppRoutes.settings ||
          route.settings.name == AppRoutes.main,
    );
  }

  @override
  Widget build(BuildContext context) {
    // สร้างเลย์เอาต์หลักของหน้า subscription
    return Scaffold(
      backgroundColor: const Color(0xFF080B0E),
      body: Stack(
        children: [
          // เอฟเฟกต์เรืองแสงพื้นหลัง
          Positioned(
            top: 0,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.08),
                    blurRadius: 150,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ปุ่มย้อนกลับ
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ส่วนหัวข้อ
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00FFB2),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'WHATRU PRO',
                        style: TextStyle(
                          color: Color(0xFF00FFB2),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                      ),
                      children: [
                        TextSpan(text: 'Full protection,\n'),
                        TextSpan(text: 'your '),
                        TextSpan(
                          text: 'schedule',
                          style: TextStyle(color: Color(0xFF00E5FF)),
                        ),
                        TextSpan(text: '.'),
                      ],
                    ),
                  ),
                  // ข้อความโปรโมชันและคำอธิบายหลักของหน้าสมัครสมาชิก
                  const SizedBox(height: 12),
                  const Text(
                    'One plan. All features. Pick the billing period that works for you.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 24),

                  // ตัวบ่งชี้สถานะขั้นตอนของขั้นตอนสมัครสมาชิก
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FFB2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 24,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // รายการแผนการสมัครสมาชิก
                  _buildPlanCard(
                    0,
                    'Weekly',
                    '฿9.75/day · billed every 7 days',
                    '฿69',
                    'per week',
                    null,
                  ),
                  const SizedBox(height: 12),
                  _buildPlanCard(
                    1,
                    'Monthly',
                    '฿6.33/day · billed every month',
                    '฿190',
                    'per month',
                    null,
                  ),
                  const SizedBox(height: 12),
                  _buildPlanCard(
                    2,
                    'Yearly',
                    '฿3.42/day · billed once a year',
                    '฿1,490',
                    'per year',
                    '฿2,280',
                    badgeText: 'SAVE 35%',
                  ),
                  const SizedBox(height: 32),

                  // รายการฟีเจอร์ที่มากับแพ็กเกจ PRO
                  const Text(
                    'EVERYTHING INCLUDED',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureRow(
                    'Scan files & links',
                    const Color(0xFF00FFB2),
                    'UNLIMITED',
                    true,
                  ),
                  _buildFeatureRow(
                    'Scan history & reports',
                    Colors.blue,
                    'INCLUDED',
                    false,
                  ),
                  _buildFeatureRow(
                    'Deep Scan',
                    Colors.deepPurpleAccent,
                    'INCLUDED',
                    false,
                  ),
                  _buildFeatureRow(
                    'No ads, ever',
                    Colors.orange,
                    'INCLUDED',
                    false,
                  ),
                  _buildFeatureRow(
                    'Priority customer support',
                    const Color(0xFF00FFB2),
                    'INCLUDED',
                    false,
                  ),
                  const SizedBox(height: 32),

                  // ปุ่มดำเนินการหลัก
                  _buildSubmitButton(),
                  const SizedBox(height: 16),

                  // ข้อความส่วนท้ายและตัวเลือกใช้งานเวอร์ชันฟรี
                  Center(
                    child: Column(
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                            children: [
                              TextSpan(text: 'No charge during trial · '),
                              TextSpan(
                                text: 'Cancel anytime',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ปุ่มตัวเลือกสำหรับใช้งานเวอร์ชันฟรี (Free Plan)
                        GestureDetector(
                          onTap: () async {
                            // อัปเดตสถานะผู้ใช้เป็น Free Plan ในฐานข้อมูล
                            if (FirebaseAuth.instance.currentUser != null) {
                              await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({
                                'isPro': false,
                                'planName': 'Free Plan',
                              });
                            }
                            _completeSubscription(context, 'Account Ready! Using Free Plan.');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(color: Colors.white24, width: 1.5),
                              borderRadius: BorderRadius.circular(24), // ปรับขอบให้โค้งมนเป็นรูปทรงแคปซูล
                            ),
                            child: const Text(
                              'Continue with Free version',
                              style: TextStyle(
                                color: Colors.white70, // ปรับสีข้อความให้สว่างขึ้นเพื่อให้อ่านง่าย
                                fontSize: 12, 
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        // สิ้นสุดส่วนการจัดการปุ่มใช้งานเวอร์ชันฟรี
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // สร้างการ์ดแนะนำแผนสมัครสมาชิกแต่ละตัวเลือก
  Widget _buildPlanCard(
    int index,
    String title,
    String subtitle,
    String price,
    String duration,
    String? oldPrice, {
    String? badgeText,
  }) {
    bool isSelected = _selectedPlan == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF00E5FF).withOpacity(0.05)
                  : const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF00E5FF)
                    : const Color(0xFF2A2F35),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // ปุ่ม Radio แบบปรับแต่งเอง
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF00E5FF)
                          : Colors.grey[700]!,
                      width: isSelected ? 6 : 1,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isSelected
                              ? const Color(0xFF00E5FF)
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      duration,
                      style: const TextStyle(
                        color: Color(0xFF00FFB2),
                        fontSize: 10,
                      ),
                    ),
                    if (oldPrice != null)
                      Text(
                        oldPrice,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ป้ายกำกับโปรโมชัน (Badge)
          if (badgeText != null && isSelected)
            Positioned(
              top: -10,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // สร้างแถวแสดงคุณสมบัติพิเศษของแผนสมัครสมาชิก
  Widget _buildFeatureRow(
    String text,
    Color iconColor,
    String badgeText,
    bool isHighlight,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.check, color: iconColor, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isHighlight
                  ? const Color(0xFF00FFB2).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isHighlight
                    ? const Color(0xFF00FFB2)
                    : const Color(0xFF2A2F35),
              ),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: isHighlight ? const Color(0xFF00FFB2) : Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // สร้างปุ่มยืนยันการเลือกแผนและจัดการการนำทาง
  Widget _buildSubmitButton() {
    bool hasSelected = _selectedPlan != -1;
    // ตรวจสอบสถานะการเข้าสู่ระบบ
    bool isLoggedIn = FirebaseAuth.instance.currentUser != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: hasSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: () async {
          if (hasSelected && isLoggedIn) {
            // แสดงการแจ้งเตือนขณะประมวลผล
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Updating your plan...', style: TextStyle(color: Colors.white),),
                backgroundColor: Color(0xFF161B22),
              ),
            );

            // กำหนดชื่อแผนจากดัชนีที่ผู้ใช้เลือก
            String planName = _selectedPlan == 0
                ? 'Weekly Pro'
                : (_selectedPlan == 1 ? 'Monthly Pro' : 'Yearly Pro');

            // อัปเดตข้อมูลแพ็กเกจของผู้ใช้ลงใน Firestore
            String uid = FirebaseAuth.instance.currentUser!.uid;
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .update({'isPro': true, 'planName': planName});

            _completeSubscription(context, 'Plan Updated Successfully!');
          } else if (hasSelected && !isLoggedIn) {
            // นำทางไปยังหน้าเข้าสู่ระบบหากยังไม่ได้ล็อกอิน
            Navigator.pushNamed(context, AppRoutes.login);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: hasSelected ? Colors.transparent : Colors.grey[400],
          disabledBackgroundColor: Colors.grey[400],
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: hasSelected
                ? const LinearGradient(
                    colors: [Color(0xFF00FFB2), Color(0xFF00E5FF)],
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // แสดงข้อความบนปุ่มตามสถานะการเข้าสู่ระบบและแผนที่เลือก
                Text(
                  hasSelected
                      ? (isLoggedIn
                            ? 'CONFIRM PLAN CHANGE'
                            : 'START FREE 7-DAY TRIAL')
                      : 'SELECT YOUR PLAN',
                  style: TextStyle(
                    color: hasSelected ? Colors.black : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                ),
                if (hasSelected) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.black,
                    size: 18,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
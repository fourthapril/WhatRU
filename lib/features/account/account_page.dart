import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/routes/app_routes.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  // ── อัปเดตชื่อผู้ใช้ใน Firestore ──
  Future<void> _updateUsername(
      BuildContext context, String uid, String newName) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'username': newName});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username updated successfully!'),
            backgroundColor: Color(0xFF00FFB2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFFF4B6C),
          ),
        );
      }
    }
  }

  // ── ไดอะล็อกแก้ไขชื่อผู้ใช้ ──
  void _showEditUsernameDialog(
    BuildContext context, {
    required String uid,
    required String currentUsername,
  }) {
    final controller =
        TextEditingController(text: currentUsername);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Username',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'New Username',
            labelStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Color(0xFF00FFB2))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL',
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _updateUsername(
                    context, uid, controller.text);
              }
              Navigator.pop(context);
            },
            child: const Text('SAVE',
                style: TextStyle(
                    color: Color(0xFF00FFB2),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ไดอะล็อกเปลี่ยนรหัสผ่าน
  // - ช่องรหัสผ่านปัจจุบัน
  // - ช่องรหัสผ่านใหม่
  // - ช่องยืนยันรหัสผ่านใหม่
  // - ปุ่มสลับการแสดง/ซ่อนรหัสผ่านทั้งสามช่อง
  // - ลิงก์ลืมรหัสผ่าน
  // ─────────────────────────────────────────────
  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController     = TextEditingController();
    final confirmPasswordController = TextEditingController();

    // สถานะการแสดงรหัสผ่านในแต่ละช่องจัดการภายในไดอะล็อก
    bool showCurrent = false;
    bool showNew     = false;
    bool showConfirm = false;
    bool isLoading   = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161B22),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.lock_outline,
                      color: Color(0xFF00FFB2), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Change Password',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── ช่องรหัสผ่านปัจจุบัน ──
                    _buildDialogPasswordField(
                      label:      'Current Password',
                      controller: currentPasswordController,
                      isObscure:  !showCurrent,
                      onToggle: () => setDialogState(
                          () => showCurrent = !showCurrent),
                    ),
                    const SizedBox(height: 16),

                    // ── ช่องรหัสผ่านใหม่ ──
                    _buildDialogPasswordField(
                      label:      'New Password',
                      controller: newPasswordController,
                      isObscure:  !showNew,
                      onToggle: () => setDialogState(
                          () => showNew = !showNew),
                    ),
                    const SizedBox(height: 16),

                    // ── ช่องยืนยันรหัสผ่านใหม่ ──
                    _buildDialogPasswordField(
                      label:      'Confirm New Password',
                      controller: confirmPasswordController,
                      isObscure:  !showConfirm,
                      onToggle: () => setDialogState(
                          () => showConfirm = !showConfirm),
                    ),
                    const SizedBox(height: 16),

                    // ── ลิงก์ลืมรหัสผ่าน ──
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _showForgotPasswordDialog(context);
                      },
                      child: const Text(
                        'Forgot your current password?',
                        style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('CANCEL',
                      style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final current =
                              currentPasswordController.text
                                  .trim();
                          final newPass =
                              newPasswordController.text.trim();
                          final confirm =
                              confirmPasswordController.text
                                  .trim();

                          // ── ตรวจสอบความถูกต้องของข้อมูล ──
                          if (current.isEmpty ||
                              newPass.isEmpty ||
                              confirm.isEmpty) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please fill in all fields.'),
                                backgroundColor:
                                    Color(0xFFFF4B6C),
                              ),
                            );
                            return;
                          }

                          if (newPass != confirm) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'New passwords do not match.'),
                                backgroundColor:
                                    Color(0xFFFF4B6C),
                              ),
                            );
                            return;
                          }

                          if (newPass.length < 6) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Password must be at least 6 characters.'),
                                backgroundColor:
                                    Color(0xFFFF4B6C),
                              ),
                            );
                            return;
                          }

                          setDialogState(
                              () => isLoading = true);

                          try {
                            final user = FirebaseAuth
                                .instance.currentUser;
                            if (user == null ||
                                user.email == null) return;

                            // ── ยืนยันตัวตนอีกครั้งด้วยรหัสผ่านปัจจุบัน ──
                            final credential =
                                EmailAuthProvider.credential(
                              email:    user.email!,
                              password: current,
                            );
                            await user
                                .reauthenticateWithCredential(
                                    credential);

                            // ── อัปเดตรหัสผ่านใหม่ ──
                            await user
                                .updatePassword(newPass);

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Password updated successfully!',
                                    style: TextStyle(
                                        color: Colors.black),
                                  ),
                                  backgroundColor:
                                      Color(0xFF00FFB2),
                                ),
                              );
                            }
                          } on FirebaseAuthException catch (e) {
                            setDialogState(
                                () => isLoading = false);
                            String message =
                                'Failed to update password.';
                            if (e.code ==
                                'wrong-password') {
                              message =
                                  'Current password is incorrect.';
                            } else if (e.code ==
                                'requires-recent-login') {
                              message =
                                  'Please log out and log in again, then retry.';
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                  backgroundColor:
                                      const Color(0xFFFF4B6C),
                                ),
                              );
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Color(0xFF00FFB2),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'UPDATE',
                          style: TextStyle(
                              color: Color(0xFF00FFB2),
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── วิดเจ็ตฟิลด์รหัสผ่านที่ใช้ซ้ำได้สำหรับไดอะล็อก ──
  Widget _buildDialogPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isObscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0B0E11),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: const Color(0xFF2A2F35)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isObscure,
            style: const TextStyle(
                color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline,
                  color: Colors.grey, size: 16),
              border: InputBorder.none,
              hintText: label,
              hintStyle: const TextStyle(
                  color: Colors.white24, fontSize: 13),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12),
              suffixIcon: IconButton(
                icon: Icon(
                  isObscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey,
                  size: 16,
                ),
                onPressed: onToggle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // ไดอะล็อกรีเซ็ตรหัสผ่าน
  // ใช้งานได้เหมือนกับหน้าล็อกอิน — ใช้ซ้ำได้จากหน้าบัญชีผู้ใช้
  // เข้าถึงได้จากลิงก์ "Forgot your current password?"
  // ─────────────────────────────────────────────
  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    bool isSending = false;

    // เติมอีเมลผู้ใช้ปัจจุบันลงในช่องโดยอัตโนมัติ
    final currentEmail =
        FirebaseAuth.instance.currentUser?.email ?? '';
    emailController.text = currentEmail;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161B22),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_reset,
                          color: Color(0xFF00FFB2), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Reset Password',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    'A reset link will be sent to your email.',
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.normal),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0E11),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF2A2F35)),
                    ),
                    child: TextField(
                      controller: emailController,
                      keyboardType:
                          TextInputType.emailAddress,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                            Icons.email_outlined,
                            color: Colors.grey,
                            size: 18),
                        border: InputBorder.none,
                        hintText: 'Your email address',
                        hintStyle: TextStyle(
                            color: Colors.white24,
                            fontSize: 14),
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSending
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('CANCEL',
                      style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final email =
                              emailController.text.trim();
                          if (email.isEmpty ||
                              !email.contains('@')) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please enter a valid email.'),
                                backgroundColor:
                                    Color(0xFFFF4B6C),
                              ),
                            );
                            return;
                          }

                          setDialogState(
                              () => isSending = true);
                          try {
                            await FirebaseAuth.instance
                                .sendPasswordResetEmail(
                                    email: email);
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Reset link sent! Check your inbox.',
                                    style: TextStyle(
                                        color: Colors.black),
                                  ),
                                  backgroundColor:
                                      Color(0xFF00FFB2),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(
                                () => isSending = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Error: ${e.toString()}'),
                                  backgroundColor: const Color(
                                      0xFFFF4B6C),
                                ),
                              );
                            }
                          }
                        },
                  child: isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Color(0xFF00FFB2),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'SEND LINK',
                          style: TextStyle(
                              color: Color(0xFF00FFB2),
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF080B0E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Your Account',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.logout,
                  color: Color(0xFFFF4B6C), size: 22),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF161B22),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(20)),
                    title: const Text('Log out',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    content: const Text(
                        'Are you sure you want to log out?',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14)),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context),
                        child: const Text('CANCEL',
                            style: TextStyle(
                                color: Colors.grey,
                                fontWeight:
                                    FontWeight.bold)),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await FirebaseAuth.instance
                              .signOut();
                          if (context.mounted) {
                            Navigator
                                .pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.main,
                              (route) => false,
                            );
                          }
                        },
                        child: const Text('LOG OUT',
                            style: TextStyle(
                                color: Color(0xFFFF4B6C),
                                fontWeight:
                                    FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: user == null
          ? _buildGuestView(context)
          : _buildLoggedInView(user.uid, context),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF161B22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FFB2)
                        .withOpacity(0.1),
                    blurRadius: 40,
                    spreadRadius: 10,
                  )
                ],
              ),
              child: const Icon(Icons.lock_person_outlined,
                  size: 60, color: Color(0xFF00FFB2)),
            ),
            const SizedBox(height: 32),
            const Text('Access Restricted',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 12),
            const Text(
              'Please log in or create an account to view your profile and sync your scan history across devices.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.5),
            ),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [
                      Color(0xFF00FFB2),
                      Color(0xFF00E5FF)
                    ]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(
                    context, AppRoutes.createAccount),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('CREATE ACCOUNT',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pushNamed(
                    context, AppRoutes.login),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[800]!),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('LOG IN',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedInView(String uid, BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF00FFB2)));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
              child: Text('User data not found.',
                  style: TextStyle(color: Colors.grey)));
        }

        final userData =
            snapshot.data!.data() as Map<String, dynamic>;
        final String username =
            userData['username'] ?? 'User';
        final String email    = userData['email']    ?? '';
        final bool   isPro    = userData['isPro']    ?? false;
        final String planName =
            userData['planName'] ?? 'Free Plan';

        String joinDate = 'Recently';
        if (userData['createdAt'] != null) {
          final date =
              (userData['createdAt'] as Timestamp).toDate();
          joinDate =
              '${date.day}/${date.month}/${date.year}';
        }

        String expiryDate = '';
        if (userData['subscriptionEnd'] != null) {
          final expiry = (userData['subscriptionEnd']
                  as Timestamp)
              .toDate();
          expiryDate =
              '${expiry.day}/${expiry.month}/${expiry.year}';
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Center(
                child: Column(
                  children: [
                    // รูปโปรไฟล์ (Avatar)
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: isPro
                                ? const Color(0xFF00FFB2)
                                : Colors.grey,
                            width: 3),
                        color: const Color(0xFF161B22),
                      ),
                      child: Icon(Icons.person,
                          size: 50,
                          color: isPro
                              ? const Color(0xFF00FFB2)
                              : Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    // ชื่อผู้ใช้และปุ่มแก้ไข
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 32),
                        Text(username,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        IconButton(
                          icon: const Icon(Icons.edit,
                              size: 18,
                              color: Color(0xFF00FFB2)),
                          onPressed: () =>
                              _showEditUsernameDialog(
                            context,
                            uid: uid,
                            currentUsername: username,
                          ),
                        ),
                      ],
                    ),

                    Text(email,
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14)),
                    const SizedBox(height: 12),

                    // ป้ายแผนสมาชิก
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPro
                            ? const Color(0xFF00FFB2)
                                .withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(20),
                        border: Border.all(
                            color: isPro
                                ? const Color(0xFF00FFB2)
                                : Colors.grey),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                              isPro
                                  ? Icons.star
                                  : Icons.shield_outlined,
                              color: isPro
                                  ? const Color(0xFF00FFB2)
                                  : Colors.grey,
                              size: 14),
                          const SizedBox(width: 6),
                          Text(planName.toUpperCase(),
                              style: TextStyle(
                                  color: isPro
                                      ? const Color(
                                          0xFF00FFB2)
                                      : Colors.grey,
                                  fontSize: 10,
                                  fontWeight:
                                      FontWeight.bold)),
                        ],
                      ),
                    ),

                    // วันที่หมดอายุแผน
                    if (isPro && expiryDate.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Expires: $expiryDate',
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12),
                      ),
                    ],

                    const SizedBox(height: 16),
                    Text('Member since: $joinDate',
                        style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // ── แถวเปลี่ยนรหัสผ่าน ──
              // จะเปิดไดอะล็อกเต็มรูปแบบที่มีช่องปัจจุบัน/ใหม่/ยืนยัน
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.lock_outline,
                      color: Colors.grey),
                  title: const Text('Change Password',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14)),
                  trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey),
                  onTap: () =>
                      _showChangePasswordDialog(context),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: Colors.white10),
              const SizedBox(height: 30),

              // สถิติการใช้งาน
              Row(
                children: [
                  Expanded(
                    child: _buildStatBox(
                      'Files Scanned',
                      '0',
                      Icons.shield_outlined,
                      const Color(0xFF00E5FF),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatBox(
                      'Threats Found',
                      '0',
                      Icons.warning_amber_rounded,
                      const Color(0xFFFF4B6C),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatBox(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(value,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
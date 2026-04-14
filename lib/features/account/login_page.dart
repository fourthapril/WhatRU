import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isObscure = true;

  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    bool isSending = false;

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
                    'Enter your email to receive a reset link.',
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
                  // ── ช่องอีเมลในไดอะล็อก ──
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0E11),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF2A2F35)),
                    ),
                    child: TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email_outlined,
                            color: Colors.grey, size: 18),
                        border: InputBorder.none,
                        hintText: 'Enter your email',
                        hintStyle: TextStyle(
                            color: Colors.white24, fontSize: 14),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 14),
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
                                    'Please enter a valid email address.'),
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
                            if (mounted) {
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
                            if (mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Error: ${e.toString()}'),
                                  backgroundColor:
                                      const Color(0xFFFF4B6C),
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
    return Scaffold(
      backgroundColor: const Color(0xFF080B0E),
      body: Stack(
        children: [
          // เอฟเฟกต์เรืองแสงพื้นหลัง
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FFB2).withOpacity(0.08),
                    blurRadius: 150,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -50,
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            // ปุ่มย้อนกลับ
                            GestureDetector(
                              onTap: () =>
                                  Navigator.pop(context),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF161B22),
                                  borderRadius:
                                      BorderRadius.circular(
                                          12),
                                ),
                                child: const Icon(
                                    Icons.arrow_back_ios_new,
                                    color: Colors.white,
                                    size: 16),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // หัวข้อหน้าล็อกอิน
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
                                  'WELCOME BACK',
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
                                  TextSpan(text: 'Log in to\n'),
                                  TextSpan(
                                    text: 'continue',
                                    style: TextStyle(
                                        color:
                                            Color(0xFF00E5FF)),
                                  ),
                                  TextSpan(text: '.'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),

                            // ช่องกรอกอีเมล
                            _buildEmailField(),
                            const SizedBox(height: 16),

                            // ช่องกรอกรหัสผ่าน
                            _buildPasswordField(),

                            // ── ลิงก์ลืมรหัสผ่าน → เปิดไดอะล็อก ──
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed:
                                    _showForgotPasswordDialog,
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            const Spacer(),
                            const SizedBox(height: 40),

                            // ปุ่มเข้าสู่ระบบ
                            GestureDetector(
                              onTap: () async {
                                if (_emailController
                                        .text.isNotEmpty &&
                                    _passwordController
                                        .text.isNotEmpty) {
                                  try {
                                    ScaffoldMessenger.of(
                                            context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Logging in...',
                                          style: TextStyle(
                                              color:
                                                  Colors.white),
                                        ),
                                        backgroundColor:
                                            Color(0xFF161B22),
                                        duration: Duration(
                                            seconds: 1),
                                      ),
                                    );

                                    await FirebaseAuth.instance
                                        .signInWithEmailAndPassword(
                                      email: _emailController
                                          .text
                                          .trim(),
                                      password:
                                          _passwordController
                                              .text
                                              .trim(),
                                    );

                                    if (context.mounted) {
                                      Navigator
                                          .pushNamedAndRemoveUntil(
                                        context,
                                        AppRoutes.main,
                                        (route) => false,
                                      );
                                    }
                                  } on FirebaseAuthException catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                              context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Login failed: ${e.message}'),
                                          backgroundColor:
                                              const Color(
                                                  0xFFFF4B6C),
                                        ),
                                      );
                                    }
                                  }
                                } else {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter email and password',
                                        style: TextStyle(
                                            color: Colors.white),
                                      ),
                                      backgroundColor:
                                          Color(0xFF161B22),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets
                                    .symmetric(vertical: 18),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00FFB2),
                                      Color(0xFF00E5FF)
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'LOG IN',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 14,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward,
                                        color: Colors.black,
                                        size: 18),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ลิงก์ลงทะเบียน
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Don't have an account? ",
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator
                                      .pushReplacementNamed(
                                          context,
                                          AppRoutes
                                              .createAccount),
                                  child: const Text(
                                    'Sign up',
                                    style: TextStyle(
                                      color: Color(0xFF00FFB2),
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EMAIL ADDRESS',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            border:
                Border.all(color: const Color(0xFF2A2F35), width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlignVertical: TextAlignVertical.center,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.email_outlined,
                  color: Colors.grey, size: 18),
              border: InputBorder.none,
              hintText: 'Enter your email',
              hintStyle:
                  TextStyle(color: Colors.white24, fontSize: 14),
              contentPadding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PASSWORD',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            border:
                Border.all(color: const Color(0xFF2A2F35), width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _isObscure,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline,
                  color: Colors.grey, size: 18),
              border: InputBorder.none,
              hintText: 'Enter your password',
              hintStyle: const TextStyle(
                  color: Colors.white24, fontSize: 14),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16),
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey,
                  size: 18,
                ),
                onPressed: () =>
                    setState(() => _isObscure = !_isObscure),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
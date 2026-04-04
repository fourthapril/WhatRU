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

  // ตัวจัดการข้อความสำหรับการรับข้อมูลอีเมลและรหัสผ่าน
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    // คืนค่าหน่วยความจำเมื่อปิดหน้าจอ
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B0E),
      body: Stack(
        children: [
          // เอฟเฟกต์เรืองแสงพื้นหลัง
          Positioned(
            top: -100, right: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00FFB2).withOpacity(0.08), blurRadius: 150, spreadRadius: 50),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -100, left: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.08), blurRadius: 150, spreadRadius: 50),
                ],
              ),
            ),
          ),

          // ส่วนเนื้อหาหลัก
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ปุ่มย้อนกลับ
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // ส่วนหัวข้อ
                            Row(
                              children: [
                                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF00FFB2), shape: BoxShape.circle)),
                                const SizedBox(width: 8),
                                const Text('WELCOME BACK', style: TextStyle(color: Color(0xFF00FFB2), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1),
                                children: [
                                  TextSpan(text: 'Log in to\n'),
                                  TextSpan(text: 'continue', style: TextStyle(color: Color(0xFF00E5FF))),
                                  TextSpan(text: '.'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),

                            // ช่องกรอกข้อมูล
                            _buildEmailField(),
                            const SizedBox(height: 16),
                            _buildPasswordField(),

                            // ปุ่มลืมรหัสผ่าน
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: const Text('Forgot Password?', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),

                            const Spacer(),
                            const SizedBox(height: 40), 

                            // ปุ่มดำเนินการเข้าสู่ระบบ
                            GestureDetector(
                              onTap: () async {
                                if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
                                  try {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Logging in...', style: TextStyle(color: Colors.white),), backgroundColor: Color(0xFF161B22), duration: Duration(seconds: 1)),
                                    );

                                    await FirebaseAuth.instance.signInWithEmailAndPassword(
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text.trim(),
                                    );

                                    if (context.mounted) {
                                      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (route) => false);
                                    }
                                  } on FirebaseAuthException catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Login failed: ${e.message}'), backgroundColor: const Color(0xFFFF4B6C)),
                                      );
                                    }
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter email and password', style: TextStyle(color: Colors.white),), backgroundColor: Color(0xFF161B22)),
                                  );
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00FFB2), Color(0xFF00E5FF)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('LOG IN', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.0)),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, color: Colors.black, size: 18),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ลิงก์สำหรับการลงทะเบียนใหม่
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Don't have an account? ", style: TextStyle(color: Colors.grey, fontSize: 13)),
                                GestureDetector(
                                  onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.createAccount),
                                  child: const Text('Sign up', style: TextStyle(color: Color(0xFF00FFB2), fontSize: 13, fontWeight: FontWeight.bold)),
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

  // วิดเจ็ตสำหรับสร้างช่องกรอกอีเมล
  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('EMAIL ADDRESS', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            border: Border.all(color: const Color(0xFF2A2F35), width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _emailController, 
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlignVertical: TextAlignVertical.center, 
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.email_outlined, color: Colors.grey, size: 18), 
              border: InputBorder.none,
              hintText: 'Enter your email',
              hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
              contentPadding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  // วิดเจ็ตสำหรับสร้างช่องกรอกรหัสผ่าน
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PASSWORD', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            border: Border.all(color: const Color(0xFF2A2F35), width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _passwordController, 
            obscureText: _isObscure,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey, size: 18), 
              border: InputBorder.none,
              hintText: 'Enter your password',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(vertical: 16), 
              suffixIcon: IconButton(
                icon: Icon(_isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey, size: 18),
                onPressed: () => setState(() => _isObscure = !_isObscure),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
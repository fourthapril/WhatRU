import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; 
import '../../core/routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  // ตัวจัดการข้อความสำหรับการรับข้อมูลจากผู้ใช้
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // ตัวแปรสำหรับจัดการสถานะการแสดงผล
  bool _isPasswordObscure = true;
  bool _isConfirmObscure = true;
  bool _isAgreed = false;

  @override
  void initState() {
    super.initState();
    // อัปเดตสถานะหน้าจอทุกครั้งเมื่อมีการเปลี่ยนแปลงข้อความในช่องกรอกข้อมูล
    _userNameController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ลอจิกการตรวจสอบความถูกต้องของข้อมูล (Validation)
  bool get _isUserNameValid => _userNameController.text.isNotEmpty;
  bool get _isEmailValid => _emailController.text.contains('@gmail.com');
  bool get _isPasswordValid => _passwordController.text.isNotEmpty;
  
  // ตรวจสอบความตรงกันของรหัสผ่าน
  bool get _isConfirmValid => _confirmPasswordController.text.isNotEmpty && 
                              _confirmPasswordController.text == _passwordController.text;

  // ตรวจสอบความสมบูรณ์ของแบบฟอร์มทั้งหมด
  bool get _isFormValid => _isUserNameValid && _isEmailValid && _isPasswordValid && _isConfirmValid && _isAgreed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B0E),
      extendBody: true, 
      body: Stack(
        children: [
          // เอฟเฟกต์เรืองแสงพื้นหลัง
          Positioned(
            top: -100, right: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF00FFB2).withOpacity(0.08), blurRadius: 150, spreadRadius: 50)],
              ),
            ),
          ),
          Positioned(
            bottom: -100, left: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.08), blurRadius: 150, spreadRadius: 50)],
              ),
            ),
          ),

          // ส่วนเนื้อหาหลัก
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 40),
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
                            const SizedBox(height: 24),

                            // ส่วนหัวข้อ
                            Row(
                              children: [
                                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF00FFB2), shape: BoxShape.circle)),
                                const SizedBox(width: 8),
                                const Text('CREATE ACCOUNT', style: TextStyle(color: Color(0xFF00FFB2), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1),
                                children: [
                                  TextSpan(text: 'Stay '),
                                  TextSpan(text: 'protected', style: TextStyle(color: Color(0xFF00E5FF))),
                                  TextSpan(text: ',\nstay ahead.'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Join WHATRU and keep your files safe\nfrom threats in real-time.',
                              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
                            ),
                            const SizedBox(height: 32),

                            // 1. ช่องกรอกชื่อผู้ใช้
                            _buildInputField(
                              label: 'USER NAME',
                              hint: 'Enter username',
                              controller: _userNameController,
                              icon: Icons.person_outline,
                              isValid: _isUserNameValid,
                              showError: false,
                            ),
                            const SizedBox(height: 16),

                            // 2. ช่องกรอกอีเมล
                            _buildInputField(
                              label: 'EMAIL ADDRESS',
                              hint: 'example@gmail.com',
                              controller: _emailController,
                              icon: Icons.email_outlined,
                              isValid: _isEmailValid,
                              showError: false,
                            ),
                            const SizedBox(height: 16),

                            // 3. ช่องกรอกรหัสผ่าน
                            _buildPasswordField(
                              label: 'PASSWORD',
                              hint: 'Enter your password',
                              controller: _passwordController,
                              isObscure: _isPasswordObscure,
                              onToggleObscure: () => setState(() => _isPasswordObscure = !_isPasswordObscure),
                              isValid: _isPasswordValid,
                            ),
                            const SizedBox(height: 16),

                            // 4. ช่องยืนยันรหัสผ่าน
                            _buildPasswordField(
                              label: 'CONFIRM PASSWORD',
                              hint: 'Re-enter your password',
                              controller: _confirmPasswordController,
                              isObscure: _isConfirmObscure,
                              onToggleObscure: () => setState(() => _isConfirmObscure = !_isConfirmObscure),
                              isValid: _isConfirmValid,
                              // ตรวจสอบและแสดงข้อผิดพลาดหากรหัสผ่านไม่ตรงกัน
                              isError: _confirmPasswordController.text.isNotEmpty && !_isConfirmValid,
                            ),
                            const SizedBox(height: 24),

                            // ช่องทำเครื่องหมายยอมรับเงื่อนไข
                            _buildTermsCheckbox(),
                            
                            // จัดสรรพื้นที่ว่าง
                            const Spacer(),
                            const SizedBox(height: 40),

                            // ปุ่มดำเนินการ (Submit)
                            _buildSubmitButton(),
                            const SizedBox(height: 24), 

                            // ลิงก์นำทางไปยังหน้าเข้าสู่ระบบ
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Already have an account? ", 
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                                  child: const Text(
                                    'Log in', 
                                    style: TextStyle(
                                      color: Color(0xFF00FFB2), 
                                      fontSize: 13, 
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
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

  // วิดเจ็ตสำหรับสร้างช่องกรอกข้อมูลประเภทข้อความทั่วไป
  Widget _buildInputField({
    required String label, required String hint, required TextEditingController controller,
    required IconData icon, required bool isValid, required bool showError,
  }) {
    Color borderColor = showError ? const Color(0xFFFF4B6C) : (isValid ? const Color(0xFF00FFB2) : const Color(0xFF2A2F35));
    Color iconColor = showError ? const Color(0xFFFF4B6C) : (isValid ? const Color(0xFF00FFB2) : Colors.grey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(color: showError ? const Color(0xFFFF4B6C) : Colors.white, fontSize: 14),
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: iconColor, size: 18),
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              // แสดงไอคอนสถานะความถูกต้องของข้อมูล
              suffixIcon: isValid 
                  ? const Icon(Icons.check, color: Color(0xFF00FFB2), size: 18) 
                  : (showError ? const Icon(Icons.close, color: Color(0xFFFF4B6C), size: 18) : null),
            ),
          ),
        ),
      ],
    );
  }

  // วิดเจ็ตสำหรับสร้างช่องกรอกรหัสผ่าน
  Widget _buildPasswordField({
    required String label, required String hint, required TextEditingController controller,
    required bool isObscure, required VoidCallback onToggleObscure,
    required bool isValid, bool isError = false,
  }) {
    Color borderColor = isError ? const Color(0xFFFF4B6C) : (isValid ? const Color(0xFF00FFB2) : const Color(0xFF2A2F35));
    Color iconColor = isError ? const Color(0xFFFF4B6C) : (isValid ? const Color(0xFF00FFB2) : Colors.grey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            obscureText: isObscure,
            style: TextStyle(color: isError ? const Color(0xFFFF4B6C) : Colors.white, fontSize: 14),
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.lock_outline, color: iconColor, size: 18),
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // แสดงไอคอนสถานะความถูกต้อง
                  if (isValid) const Icon(Icons.check, color: Color(0xFF00FFB2), size: 18),
                  if (isError) const Icon(Icons.close, color: Color(0xFFFF4B6C), size: 18),
                  
                  // ปุ่มสลับการแสดงรหัสผ่าน
                  IconButton(
                    icon: Icon(isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey, size: 18),
                    onPressed: onToggleObscure,
                  ),
                ],
              ),
            ),
          ),
        ),
        // ข้อความแจ้งเตือนข้อผิดพลาด
        if (isError)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 4),
            child: Text('Passwords do not match', style: TextStyle(color: Color(0xFFFF4B6C), fontSize: 10)),
          ),
      ],
    );
  }

  // วิดเจ็ตสำหรับแสดงช่องทำเครื่องหมายยอมรับเงื่อนไขการให้บริการ
  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isAgreed = !_isAgreed),
          child: Container(
            width: 20, height: 20,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: _isAgreed ? const Color(0xFF00FFB2).withOpacity(0.1) : Colors.transparent,
              border: Border.all(color: _isAgreed ? const Color(0xFF00FFB2) : Colors.grey, width: 1.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: _isAgreed ? const Icon(Icons.check, size: 14, color: Color(0xFF00FFB2)) : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service', 
                  style: const TextStyle(color: Color(0xFF00FFB2), fontWeight: FontWeight.bold),
                  // เชื่อมโยงการนำทางไปยังหน้าข้อกำหนด
                  recognizer: TapGestureRecognizer()..onTap = () => Navigator.pushNamed(context, AppRoutes.tos),
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy', 
                  style: const TextStyle(color: Color(0xFF00FFB2), fontWeight: FontWeight.bold),
                  recognizer: TapGestureRecognizer()..onTap = () => Navigator.pushNamed(context, AppRoutes.tos), 
                ),
                const TextSpan(text: ' of WHATRU.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // วิดเจ็ตปุ่มยืนยันการดำเนินการ
  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: () async {
        if (_isFormValid) {
          // แสดงสถานะการประมวลผล
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Creating account...', style: TextStyle(color: Colors.white),), backgroundColor: Color(0xFF161B22), duration: Duration(seconds: 1)),
          );

          try {
            // 1. สร้างบัญชีผู้ใช้ใหม่ผ่าน Firebase Authentication
            UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

            // 2. บันทึกข้อมูลโปรไฟล์ผู้ใช้ลงใน Firestore
            await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
              'username': _userNameController.text.trim(),
              'email': _emailController.text.trim(),
              'isPro': false, 
              'createdAt': FieldValue.serverTimestamp(),
            });

            // 3. นำทางไปยังหน้า Subscription เมื่อสำเร็จ
            if (context.mounted) {
              Navigator.pushNamed(context, AppRoutes.subscription);
            }

          } on FirebaseAuthException catch (e) {
            // จัดการและแสดงข้อผิดพลาดจากการสร้างบัญชี
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.message ?? 'Error creating account'), backgroundColor: const Color(0xFFFF4B6C)),
              );
            }
          }
        } else {
          // แจ้งเตือนกรณีข้อมูลไม่ครบถ้วน
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please complete all fields correctly.', style: TextStyle(color: Colors.white),), backgroundColor: Color(0xFF161B22)),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: _isFormValid ? const LinearGradient(colors: [Color(0xFF00FFB2), Color(0xFF00E5FF)]) : null,
          color: _isFormValid ? null : const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isFormValid ? [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('CREATE ACCOUNT', style: TextStyle(color: _isFormValid ? Colors.black : Colors.grey, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.0)),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward, color: _isFormValid ? Colors.black : Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../themes/app_colors.dart';
import '../services/biometric_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  
  // Biometric State
  final _biometricService = BiometricService();
  bool _canCheckBiometrics = false;
  bool _hasCredentials = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _biometricService.isBiometricAvailable();
      final credentials = await _biometricService.getCredentials();
      if (mounted) {
        setState(() {
          _canCheckBiometrics = canCheck;
          _hasCredentials = credentials != null;
        });
      }
    } catch (e) {
      // Biometrics not accessible (likely Web/HTTP)
      debugPrint('Biometrics warning: $e');
    }
  }

  Future<void> _loginWithBiometrics() async {
    final authenticated = await _biometricService.authenticate();
    if (authenticated) {
      final credentials = await _biometricService.getCredentials();
      if (credentials != null) {
        _usernameController.text = credentials['username']!;
        _passwordController.text = credentials['password']!;
        await _login();
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (success) {
       // Save credentials if success
       if (await _biometricService.isBiometricAvailable()) {
         await _biometricService.saveCredentials(
            _usernameController.text.trim(),
            _passwordController.text,
         );
       }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Đăng nhập thất bại'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _quickLogin(String username, String password) {
    _usernameController.text = username;
    _passwordController.text = password;
    _login();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          // 1. Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback gradient if image fails/missing
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF0F172A), Color(0xFF020617)],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // 2. Dark Overlay Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3), // Top lighter
                    Colors.black.withOpacity(0.6), // Middle
                    AppColors.darkBackground.withOpacity(0.95), // Bottom solid
                  ],
                  stops: const [0.0, 0.4, 0.9],
                ),
              ),
            ),
          ),

          // 3. Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),
                        // Logo
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.neonGreen,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.neonGreen,
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.sports_tennis,
                              color: Colors.black,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Title
                        const Text(
                          'PickleBall Club',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'QUẢN LÝ SÂN ĐẤU CỦA BẠN',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neonGreen,
                            letterSpacing: 2.0,
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Welcome Text
                        const Text(
                          'Chào mừng trở lại!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Đăng nhập tài khoản để tiếp tục.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // FORM
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Username Label
                              const Text(
                                'Email hoặc Tên đăng nhập',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Username Input
                              TextFormField(
                                controller: _usernameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: _buildInputDecoration('Nhập email của bạn'),
                                validator: (val) => val!.isEmpty ? 'Vui lòng nhập' : null,
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Password Label
                              const Text(
                                'Mật khẩu',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Password Input
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(color: Colors.white),
                                decoration: _buildInputDecoration('Nhập mật khẩu').copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.white60,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (val) => val!.isEmpty ? 'Vui lòng nhập mật khẩu' : null,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Login Button Row
                        Row(
                          children: [
                            // Main Login Button
                            Expanded(
                              child: Consumer<AuthProvider>(
                                builder: (context, auth, _) {
                                  return SizedBox(
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: auth.isLoading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.neonGreen,
                                        foregroundColor: Colors.black,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        shadowColor: AppColors.neonGreen.withOpacity(0.5),
                                      ),
                                      child: auth.isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                                            )
                                          : const Text(
                                              'Đăng nhập',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            
                            // Biometric Button (if available)
                            if (_canCheckBiometrics && _hasCredentials) ...[
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 56,
                                height: 56,
                                child: OutlinedButton(
                                  onPressed: _loginWithBiometrics,
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    backgroundColor: Colors.white.withOpacity(0.05),
                                  ),
                                  child: const Icon(Icons.fingerprint, color: AppColors.neonGreen, size: 28),
                                ),
                              ),
                            ],
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Forgot/Register Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                'Quên mật khẩu?',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'Đăng ký ngay',
                                style: TextStyle(
                                  color: AppColors.neonGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Quick Access Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'VAI TRÒ TRUY CẬP NHANH',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Quick Access Grid
                        Row(
                          children: [
                            Expanded(child: _buildRoleButton('Admin', Icons.security, 'admin', 'Admin@123')),
                            const SizedBox(width: 12),
                            Expanded(child: _buildRoleButton('Thủ quỹ', Icons.account_balance_wallet, 'thuquy', 'Thuquy@123')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildRoleButton('Trọng tài', Icons.sports, 'trongtai', 'Trongtai@123')),
                            const SizedBox(width: 12),
                            Expanded(child: _buildRoleButton('Hội viên', Icons.person, 'member01', 'Member@123')),
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                        const Center(
                          child: Text(
                            '© 2026 Vợt Thủ Phố Núi - PCM System',
                            style: TextStyle(color: Colors.white30, fontSize: 11),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
      filled: true,
      fillColor: AppColors.darkSurface, // Dark container
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: AppColors.neonGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  Widget _buildRoleButton(String label, IconData icon, String user, String pass) {
    return InkWell(
      onTap: () => _quickLogin(user, pass),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.neonGreen, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

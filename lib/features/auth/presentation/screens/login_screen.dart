import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:desktop_medassist/app/router/route_paths.dart';
import 'package:desktop_medassist/features/auth/presentation/controller/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool showSignUpInitially;

  const LoginScreen({super.key, this.showSignUpInitially = false});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late int
  _authView; // 0 = login, 1 = signUp, 2 = forgotPassword, 3 = resetPassword

  // Form keys and Controllers
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();
  final _forgotFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureNewPassword = true;
  bool _rememberMe = false;
  bool _agreeTerms = false;
  bool _isLoading = false;
  bool _otpSent = false;
  String? _resetToken;

  @override
  void initState() {
    super.initState();
    _authView = widget.showSignUpInitially ? 1 : 0;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_loginFormKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final success = await ref
          .read(authControllerProvider.notifier)
          .login(
            email: _emailController.text,
            password: _passwordController.text,
          );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          context.go(RoutePaths.dashboard);
        } else {
          final errorMsg =
              ref.read(authControllerProvider).errorMessage ?? 'Login failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  void _handleSignup() async {
    if (_signupFormKey.currentState!.validate()) {
      if (!_agreeTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please agree to the Terms of Service & Privacy Policy.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final success = await ref
          .read(authControllerProvider.notifier)
          .register(
            email: _emailController.text,
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
            fullName: _nameController.text,
          );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          context.go(RoutePaths.dashboard);
        } else {
          final errorMsg =
              ref.read(authControllerProvider).errorMessage ??
              'Registration failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1050;
    const primaryTeal = Color(0xFF0D9488);
    const darkSlate = Color(0xFF0F172A);
    const softGrey = Color(0xFF64748B);
    const borderGrey = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC), // Off-white clean layout
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Center(
                          child: Container(
                            width: isDesktop ? 1200 : 460,
                            padding: EdgeInsets.symmetric(
                              vertical: isDesktop ? 20 : 10,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Left Visual Branding Panel (Desktop Only - Static & Premium)
                                if (isDesktop)
                                  Expanded(
                                    flex: 6,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        right: 80.0,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            child: Image.asset(
                                              'assets/logo/image.png',
                                              width: 180,
                                              height: 180,
                                              fit: BoxFit.contain,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    Icons
                                                        .medical_services_rounded,
                                                    size: 140,
                                                    color: primaryTeal,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 36),
                                          const Text(
                                            'Secured.',
                                            style: TextStyle(
                                              color: primaryTeal,
                                              fontSize: 48,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -1.0,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'HIPAA-compliant security for clinical data with military-grade encryption.',
                                            style: TextStyle(
                                              color: softGrey,
                                              fontSize: 16,
                                              height: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: 32),
                                          _buildDashboardPreview(
                                            primaryTeal,
                                            darkSlate,
                                            borderGrey,
                                          ),
                                          const SizedBox(height: 32),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildInfoCard(
                                                  icon: Icons.shield_outlined,
                                                  title: 'DATA ACCURACY',
                                                  value: '99.9% Verified',
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: _buildInfoCard(
                                                  icon: Icons
                                                      .lock_outline_rounded,
                                                  title: 'COMPLIANCE',
                                                  value: '24/7 Global',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // Right Panel (Swaps between Login and Signup with elegant transition)
                                Expanded(
                                  flex: 5,
                                  child: Center(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 420,
                                      ),
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 350,
                                        ),
                                        switchInCurve: Curves.easeInOutCubic,
                                        switchOutCurve: Curves.easeInOutCubic,
                                        transitionBuilder:
                                            (
                                              Widget child,
                                              Animation<double> animation,
                                            ) {
                                              return FadeTransition(
                                                opacity: animation,
                                                child: SlideTransition(
                                                  position: Tween<Offset>(
                                                    begin: const Offset(
                                                      0.04,
                                                      0,
                                                    ),
                                                    end: Offset.zero,
                                                  ).animate(animation),
                                                  child: child,
                                                ),
                                              );
                                            },
                                        child: _authView == 0
                                            ? _buildLoginForm(
                                                primaryTeal,
                                                darkSlate,
                                                softGrey,
                                                borderGrey,
                                              )
                                            : _authView == 1
                                            ? _buildSignupForm(
                                                primaryTeal,
                                                darkSlate,
                                                softGrey,
                                              )
                                            : _authView == 2
                                            ? _buildForgotPasswordForm(
                                                primaryTeal,
                                                darkSlate,
                                                softGrey,
                                              )
                                            : _buildResetPasswordForm(
                                                primaryTeal,
                                                darkSlate,
                                                softGrey,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Elegant Footer
                      Padding(
                        padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 14,
                                  color: softGrey,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'HIPAA COMPLIANT',
                                  style: TextStyle(
                                    color: softGrey,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 14,
                                  color: softGrey,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'SSL SECURED',
                                  style: TextStyle(
                                    color: softGrey,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {},
                                  child: const Text(
                                    'PRIVACY',
                                    style: TextStyle(
                                      color: softGrey,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                GestureDetector(
                                  onTap: () {},
                                  child: const Text(
                                    'TERMS',
                                    style: TextStyle(
                                      color: softGrey,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginForm(
    Color primaryTeal,
    Color darkSlate,
    Color softGrey,
    Color borderGrey,
  ) {
    return Container(
      key: const ValueKey(
        'LoginForm',
      ), // Unique Key for AnimatedSwitcher placed on Container
      child: Form(
        key: _loginFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back.',
              style: TextStyle(
                color: darkSlate,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your credentials to access your clinical dashboard.',
              style: TextStyle(color: softGrey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 36),
            _buildLabel('EMAIL ADDRESS'),
            _buildTextField(
              controller: _emailController,
              hint: 'name@clinic.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (val) {
                if (val == null || val.isEmpty)
                  return 'Please enter your email';
                // ignore: deprecated_member_use
                if (!RegExp(
                  r'^^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(val)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabel('PASSWORD'),
                GestureDetector(
                  onTap: () => setState(() => _authView = 2),
                  child: Text(
                    'FORGOT PASSWORD?',
                    style: TextStyle(
                      color: primaryTeal,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            _buildTextField(
              controller: _passwordController,
              hint: 'Enter your password',
              icon: Icons.lock_outline_rounded,
              obscure: _obscurePassword,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: softGrey,
                  size: 18,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (val) => val == null || val.isEmpty
                  ? 'Please enter your password'
                  : null,
              onFieldSubmitted: (_) => _handleLogin(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  height: 18,
                  width: 18,
                  child: Checkbox(
                    value: _rememberMe,
                    activeColor: primaryTeal,
                    checkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: const BorderSide(
                      color: Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                    onChanged: (val) =>
                        setState(() => _rememberMe = val ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Remember me',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: primaryTeal,
                boxShadow: [
                  BoxShadow(
                    color: primaryTeal.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'Sign In to Dashboard',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Container(height: 1, color: borderGrey)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'OR CONTINUE WITH',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(child: Container(height: 1, color: borderGrey)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSocialButton(
                    onTap: () {},
                    icon: const Icon(
                      Icons.g_mobiledata_rounded,
                      size: 26,
                      color: Colors.red,
                    ),
                    label: 'Google',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSocialButton(
                    onTap: () {},
                    icon: const Icon(
                      Icons.security_outlined,
                      size: 16,
                      color: Colors.blueGrey,
                    ),
                    label: 'SSO',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'New to MedAssist? ',
                  style: TextStyle(color: softGrey, fontSize: 13),
                ),
                GestureDetector(
                  onTap: () =>
                      setState(() => _authView = 1), // Transition dynamically
                  child: Text(
                    'Create an account',
                    style: TextStyle(
                      color: primaryTeal,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupForm(Color primaryTeal, Color darkSlate, Color softGrey) {
    return Container(
      key: const ValueKey(
        'SignupForm',
      ), // Unique Key for AnimatedSwitcher placed on Container
      child: Form(
        key: _signupFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create an Account',
              style: TextStyle(
                color: darkSlate,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get started with MedAssist for your clinical practice.',
              style: TextStyle(color: softGrey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            _buildLabel('FULL NAME'),
            _buildTextField(
              controller: _nameController,
              hint: 'Dr. John Doe',
              icon: Icons.person_outline_rounded,
              validator: (val) =>
                  val == null || val.isEmpty ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 20),
            _buildLabel('EMAIL ADDRESS'),
            _buildTextField(
              controller: _emailController,
              hint: 'name@clinic.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (val) {
                if (val == null || val.isEmpty)
                  return 'Please enter your email';
                // ignore: deprecated_member_use
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(val)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildLabel('PASSWORD'),
            _buildTextField(
              controller: _passwordController,
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscure: _obscurePassword,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (val) => val == null || val.length < 6
                  ? 'Password must be at least 6 characters'
                  : null,
              onFieldSubmitted: (_) => _handleSignup(),
            ),
            const SizedBox(height: 20),
            _buildLabel('CONFIRM PASSWORD'),
            _buildTextField(
              controller: _confirmPasswordController,
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscure: _obscureConfirmPassword,
              suffix: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty)
                  return 'Please confirm your password';
                if (val != _passwordController.text)
                  return 'Passwords do not match';
                return null;
              },
              onFieldSubmitted: (_) => _handleSignup(),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _agreeTerms,
                    activeColor: primaryTeal,
                    checkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: const BorderSide(
                      color: Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                    onChanged: (val) =>
                        setState(() => _agreeTerms = val ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: RichText(
                      text: TextSpan(
                        text: 'I agree to the ',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: InkWell(
                              onTap: () {},
                              child: Text(
                                'Terms of Service',
                                style: TextStyle(
                                  color: primaryTeal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: InkWell(
                              onTap: () {},
                              child: Text(
                                'Privacy Policy',
                                style: TextStyle(
                                  color: primaryTeal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: primaryTeal,
                boxShadow: [
                  BoxShadow(
                    color: primaryTeal.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSignup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        'Create Account',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
                GestureDetector(
                  onTap: () =>
                      setState(() => _authView = 0), // Transition dynamically
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      color: primaryTeal,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF475569),
          fontSize: 10,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onTap,
    required Widget icon,
    required String label,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFCBD5E1)),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardPreview(
    Color primaryTeal,
    Color darkSlate,
    Color borderGrey,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: primaryTeal.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.analytics_outlined,
                      color: primaryTeal,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Clinical Insights',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: darkSlate,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildMockBar(35, primaryTeal.withValues(alpha: 0.3)),
              _buildMockBar(55, primaryTeal.withValues(alpha: 0.5)),
              _buildMockBar(25, primaryTeal.withValues(alpha: 0.3)),
              _buildMockBar(70, primaryTeal.withValues(alpha: 0.8)),
              _buildMockBar(90, primaryTeal),
              _buildMockBar(45, primaryTeal.withValues(alpha: 0.5)),
              _buildMockBar(65, primaryTeal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMockBar(double height, Color color) {
    return Container(
      width: 32,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    const primaryTeal = Color(0xFF0D9488);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryTeal, size: 18),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: primaryTeal,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordForm(
    Color primaryTeal,
    Color darkSlate,
    Color softGrey,
  ) {
    return Container(
      key: const ValueKey('ForgotPasswordForm'),
      child: Form(
        key: _forgotFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _otpSent ? 'Verify OTP Code' : 'Recover Password',
              style: TextStyle(
                color: darkSlate,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _otpSent
                  ? 'We have sent a 6-digit numeric OTP to your email. Enter it below to verify your account.'
                  : 'Enter your registered email address below. We will send you a 6-digit numeric recovery verification OTP.',
              style: TextStyle(color: softGrey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),

            // EMAIL ADDRESS FIELD (Read-Only if OTP is already sent)
            _buildLabel('EMAIL ADDRESS'),
            _buildTextField(
              controller: _emailController,
              hint: 'name@clinic.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (val) {
                if (val == null || val.isEmpty)
                  return 'Please enter your email';
                // ignore: deprecated_member_use
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(val)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),

            // STEP 2: DYNAMIC SECOND SECTION (Appears below in the same form on OTP send success)
            if (_otpSent) ...[
              const SizedBox(height: 18),
              _buildLabel('6-DIGIT OTP CODE'),
              _buildTextField(
                controller: _otpController,
                hint: '123456',
                icon: Icons.pin_outlined,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return 'Please enter the 6-digit OTP';
                  if (val.length != 6 || int.tryParse(val) == null) {
                    return 'OTP must be exactly 6 numeric digits';
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 28),

            // PRIMARY ACTION BUTTON (Toggles between Send OTP and Verify OTP)
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                ),
              ),
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_forgotFormKey.currentState!.validate()) {
                          setState(() {
                            _isLoading = true;
                          });

                          if (!_otpSent) {
                            // Step 1: Send Recovery OTP
                            final success = await ref
                                .read(authControllerProvider.notifier)
                                .forgotPassword(email: _emailController.text);

                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Recovery code sent successfully! Please check your email.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Color(0xFF0D9488),
                                  ),
                                );
                                setState(() {
                                  _otpSent = true;
                                });
                              } else {
                                final error =
                                    ref
                                        .read(authControllerProvider)
                                        .errorMessage ??
                                    'Request failed';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(error),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: const Color(0xFFEF4444),
                                  ),
                                );
                              }
                            }
                          } else {
                            // Step 2: Verify OTP
                            final resetToken = await ref
                                .read(authControllerProvider.notifier)
                                .verifyResetOtp(
                                  email: _emailController.text,
                                  otp: _otpController.text,
                                );

                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });

                              if (resetToken != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'OTP verified successfully! Create your new password now.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Color(0xFF0D9488),
                                  ),
                                );
                                setState(() {
                                  _resetToken = resetToken;
                                  _authView =
                                      3; // Navigate directly to reset password view
                                });
                              } else {
                                final error =
                                    ref
                                        .read(authControllerProvider)
                                        .errorMessage ??
                                    'Invalid OTP code';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(error),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: const Color(0xFFEF4444),
                                  ),
                                );
                              }
                            }
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        _otpSent ? 'VERIFY OTP' : 'SEND RECOVERY OTP',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // BACK ACTION (Handles state cleaning on backing out)
            Center(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _otpSent = false;
                    _otpController.clear();
                    _newPasswordController.clear();
                    _authView = 0;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      color: primaryTeal,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'BACK TO LOGIN',
                      style: TextStyle(
                        color: primaryTeal,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetPasswordForm(
    Color primaryTeal,
    Color darkSlate,
    Color softGrey,
  ) {
    return Container(
      key: const ValueKey('ResetPasswordForm'),
      child: Form(
        key: _resetFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reset Password',
              style: TextStyle(
                color: darkSlate,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your recovery code has been verified. Please enter your new secure password below.',
              style: TextStyle(color: softGrey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 28),

            _buildLabel('NEW SECURE PASSWORD'),
            _buildTextField(
              controller: _newPasswordController,
              hint: '••••••••',
              icon: Icons.lock_reset_rounded,
              obscure: _obscureNewPassword,
              suffix: IconButton(
                icon: Icon(
                  _obscureNewPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureNewPassword = !_obscureNewPassword),
              ),
              validator: (val) {
                if (val == null || val.isEmpty)
                  return 'Please enter a new password';
                if (val.length < 8)
                  return 'Password must be at least 8 characters';
                return null;
              },
              onFieldSubmitted: (_) async {
                // Allow enter key to submit
              },
            ),

            const SizedBox(height: 28),

            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                ),
              ),
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_resetFormKey.currentState!.validate()) {
                          setState(() {
                            _isLoading = true;
                          });

                          final resetSuccess = await ref
                              .read(authControllerProvider.notifier)
                              .resetPassword(
                                resetToken: _resetToken ?? '',
                                newPassword: _newPasswordController.text,
                              );

                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });

                            if (resetSuccess) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Password reset successful! You can now log in with your new password.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Color(0xFF0D9488),
                                ),
                              );
                              setState(() {
                                _otpSent = false;
                                _resetToken = null;
                                _otpController.clear();
                                _newPasswordController.clear();
                                _authView = 0; // Return to login view
                              });
                            } else {
                              final error =
                                  ref
                                      .read(authControllerProvider)
                                      .errorMessage ??
                                  'Reset failed';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(error),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: const Color(0xFFEF4444),
                                ),
                              );
                            }
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'SUBMIT PASSWORD RESET',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // BACK ACTION (Handles state cleaning on backing out)
            Center(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _otpSent = false;
                    _resetToken = null;
                    _otpController.clear();
                    _newPasswordController.clear();
                    _authView = 0;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      color: primaryTeal,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'BACK TO LOGIN',
                      style: TextStyle(
                        color: primaryTeal,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
